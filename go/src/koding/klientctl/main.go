// Klientctl's main package implements the binary `kd`.
//
// kd allows you to use your local IDE and tools to interact with a Koding VMs.
// It uses FUSE (and other methods) to mount the remote VM as a filesystem onto
// your local machine.
//
// In addition it allows you to run commands/ssh on your remote machine from local
// terminal.
//
// TODO: Most kd commands are implemented in this main package, but they're being
// moved to their own packages.
package main

import (
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"runtime"

	"koding/klientctl/auth"
	"koding/klientctl/config"
	"koding/klientctl/ctlcli"
	"koding/klientctl/endpoint/kloud"
	"koding/klientctl/util"

	"github.com/codegangsta/cli"
	"github.com/koding/logging"
)

// ExitingWithMessageCommand is a function which prints the given message to
// Stdout. Useful for printig a message to the user in a convenient single-use way.
type ExitingWithMessageCommand func(*cli.Context, logging.Logger, string) (string, int)

// sudoRequiredFor is the default list of commands that require sudo.
// The actual handling of this list is done in the SudoRequired func.
var sudoRequiredFor = []string{
	"install",
	"uninstall",
	"start",
	"stop",
	"restart",
	"update",
}

// log is used as a global loggger, for commands like ListCommand that
// need refactoring to support instance based commands.
//
// TODO: Remove this after all commands have been refactored into structs. Ie, the
// cli rewrite.
var log logging.Logger

var (
	debug        = os.Getenv("KD_DEBUG") == "1"
	experimental = os.Getenv("KD_EXPERIMENTAL") == "1" || config.Konfig.Environment == "development"
)

func main() {
	run(os.Args)
}

func run(args []string) {
	// For forward-compatibility with go1.5+, where GOMAXPROCS is
	// always set to a number of available cores.
	runtime.GOMAXPROCS(runtime.NumCPU())

	debug = debug || config.Konfig.Debug

	// The writer used for the logging output. Either a file, or /dev/null
	var logWriter io.Writer

	f, err := os.OpenFile(LogFilePath, os.O_WRONLY|os.O_APPEND, 0666)
	if err != nil {
		// Rather than exit `kd` because we are unable to log, we simple disable logging
		// by writing to /dev/null. This also measn that even if we can't load the log
		// file, the log instance is valid and doesn't have to be checked for being
		// nil before every usage.
		logWriter = ioutil.Discard
	} else {
		logWriter = f
		ctlcli.CloseOnExit(f)
	}

	// Setting the handler to debug, because various methods allow a
	// debug option, and this saves us from having to set the handler level every time.
	// This only sets handler, not the actual loglevel.
	handler := logging.NewWriterHandler(logWriter)
	handler.SetLevel(logging.DEBUG)
	// Create our logger.
	//
	// TODO: Single commit temporary solution, need to remove the above logger
	// in favor of this.
	log = logging.NewLogger("kd")
	log.SetHandler(handler)
	log.Info("kd binary called with: %s", os.Args)

	if debug {
		log.SetLevel(logging.DEBUG)
	}

	// Check if the command the user is giving requires sudo.
	if err := AdminRequired(os.Args, sudoRequiredFor, util.NewPermissions()); err != nil {
		// In the event of an error, simply print the error to the user
		// and exit.
		fmt.Println("Error: this command requires sudo.")
		ctlcli.Close()
		os.Exit(10)
	}

	kloud.DefaultLog = log
	testKloudHook(kloud.DefaultClient)
	defer ctlcli.Close()

	// TODO(leeola): deprecate this default, instead passing it as a dependency
	// to the users of it.
	//
	// init the defaultHealthChecker with the log.
	defaultHealthChecker = NewDefaultHealthChecker(log)

	app := cli.NewApp()
	app.Name = config.Name
	app.Version = getReadableVersion(config.Version)
	app.EnableBashCompletion = true

	app.Commands = []cli.Command{
		{
			Name:      "list",
			ShortName: "ls",
			Usage:     "List running machines for user.",
			Action:    ctlcli.ExitAction(CheckUpdateFirst(ListCommand, log, "list")),
			Flags: []cli.Flag{
				cli.BoolFlag{
					Name:  "json",
					Usage: "Output in JSON format",
				},
				cli.BoolFlag{
					Name:  "all",
					Usage: "Include machines that have been offline for more than 24h.",
				},
			},
			Subcommands: []cli.Command{
				{
					Name:   "mounts",
					Usage:  "List the mounted machines.",
					Action: ctlcli.ExitAction(CheckUpdateFirst(MountsCommand, log, "mounts")),
					Flags: []cli.Flag{
						cli.BoolFlag{
							Name:  "json",
							Usage: "Output in JSON format",
						},
					},
				},
			},
		},
		{
			Name:        "version",
			Usage:       "Display version information.",
			HideHelp:    true,
			Description: cmdDescriptions["version"],
			Action:      ctlcli.ExitAction(VersionCommand, log, "version"),
		},
		{
			Name:        "mount",
			ShortName:   "m",
			Usage:       "Mount a remote folder to a local folder.",
			Description: cmdDescriptions["mount"],
			Flags: []cli.Flag{
				cli.StringFlag{
					Name:  "remotepath, r",
					Usage: "Full path of remote folder in machine to mount.",
				},
				cli.BoolFlag{
					Name:  "oneway-sync, s",
					Usage: "Copy remote folder to local and sync on interval. (fastest runtime).",
				},
				cli.IntFlag{
					Name:  "oneway-interval",
					Usage: "Sets how frequently local folder will sync with remote, in seconds. ",
					Value: 2,
				},
				cli.BoolFlag{
					Name:  "fuse, f",
					Usage: "Mount the remote folder via Fuse.",
				},
				cli.BoolFlag{
					Name:  "noprefetch-meta, p",
					Usage: "For fuse: Retrieve only top level folder/files. Rest is fetched on request (fastest to mount).",
				},
				cli.BoolFlag{
					Name:  "prefetch-all, a",
					Usage: "For fuse: Prefetch all contents of the remote directory up front.",
				},
				cli.IntFlag{
					Name:  "prefetch-interval",
					Usage: "For fuse: Sets how frequently remote folder will sync with local, in seconds.",
				},
				cli.BoolFlag{
					Name:  "nowatch, w",
					Usage: "For fuse: Disable watching for changes on remote machine.",
				},
				cli.BoolFlag{
					Name:  "noignore, i",
					Usage: "For fuse: Retrieve all files and folders, including ignored folders like .git & .svn.",
				},
				cli.BoolFlag{
					Name:  "trace, t",
					Usage: "Turn on trace logs.",
				},
			},
			Action: ctlcli.FactoryAction(MountCommandFactory, log, "mount"),
			BashComplete: ctlcli.FactoryCompletion(
				MountCommandFactory, log, "mount",
			),
		},
		{
			Name:        "unmount",
			ShortName:   "u",
			Usage:       "Unmount previously mounted machine.",
			Description: cmdDescriptions["unmount"],
			Action:      ctlcli.FactoryAction(UnmountCommandFactory, log, "unmount"),
		},
		{
			Name:        "remount",
			ShortName:   "r",
			Usage:       "Remount previously mounted machine using same settings.",
			Description: cmdDescriptions["remount"],
			Action:      ctlcli.ExitAction(RemountCommandFactory, log, "remount"),
		},
		{
			Name:        "ssh",
			ShortName:   "s",
			Usage:       "SSH into the machine.",
			Description: cmdDescriptions["ssh"],
			Flags: []cli.Flag{
				cli.BoolFlag{
					Name: "debug",
				},
				cli.StringFlag{
					Name:  "username",
					Usage: "The username to ssh into on the remote machine.",
				},
			},
			Action: ctlcli.ExitAction(CheckUpdateFirst(SSHCommandFactory, log, "ssh")),
		},
		{
			Name:            "run",
			Usage:           "Run command on remote or local machine.",
			Description:     cmdDescriptions["run"],
			Action:          ctlcli.ExitAction(RunCommandFactory, log, "run"),
			SkipFlagParsing: true,
		},
		{
			Name:   "repair",
			Usage:  "Repair the given mount",
			Action: ctlcli.FactoryAction(RepairCommandFactory, log, "repair"),
		},
		{
			Name:        "status",
			Usage:       fmt.Sprintf("Check status of the %s.", config.KlientName),
			Description: cmdDescriptions["status"],
			Action:      ctlcli.ExitAction(StatusCommand, log, "status"),
		},
		{
			Name:        "update",
			Usage:       fmt.Sprintf("Update %s to latest version.", config.KlientName),
			Description: cmdDescriptions["update"],
			Action:      ctlcli.ExitAction(UpdateCommand, log, "update"),
			Flags: []cli.Flag{
				cli.IntFlag{
					Name:  "kd-version",
					Usage: "Version of KD (klientctl) to update to.",
				},
				cli.StringFlag{
					Name:  "kd-channel",
					Usage: "Channel (production|development) to download update from.",
				},
				cli.IntFlag{
					Name:  "klient-version",
					Usage: "Version of klient to update to.",
				},
				cli.StringFlag{
					Name:  "klient-channel",
					Usage: "Channel (production|development) to download update from.",
				},
				cli.BoolFlag{
					Name:  "force",
					Usage: "Updates kd & klient to latest available version.",
				},
				cli.BoolFlag{
					Name:   "continue",
					Usage:  "Internal use only.",
					Hidden: true,
				},
			},
		},
		{
			Name:        "restart",
			Usage:       fmt.Sprintf("Restart the %s.", config.KlientName),
			Description: cmdDescriptions["restart"],
			Action:      ctlcli.ExitAction(RestartCommand, log, "restart"),
		},
		{
			Name:        "start",
			Usage:       fmt.Sprintf("Start the %s.", config.KlientName),
			Description: cmdDescriptions["start"],
			Action:      ctlcli.ExitAction(StartCommand, log, "start"),
		},
		{
			Name:        "stop",
			Usage:       fmt.Sprintf("Stop the %s.", config.KlientName),
			Description: cmdDescriptions["stop"],
			Action:      ctlcli.ExitAction(StopCommand, log, "stop"),
		},
		{
			Name:        "uninstall",
			Usage:       fmt.Sprintf("Uninstall the %s.", config.KlientName),
			Description: cmdDescriptions["uninstall"],
			Action:      ExitWithMessage(UninstallCommand, log, "uninstall"),
		},
		{
			Name:        "install",
			Usage:       fmt.Sprintf("Install the %s.", config.KlientName),
			Description: cmdDescriptions["install"],
			Flags: []cli.Flag{
				cli.StringFlag{
					Name:  "kontrol, k",
					Usage: "Specify an alternate Kontrol",
				},
			},
			Action: ctlcli.ExitErrAction(InstallCommandFactory, log, "install"),
		},
		{
			Name:     "metrics",
			Usage:    fmt.Sprintf("Internal use only."),
			HideHelp: true,
			Action:   ctlcli.ExitAction(MetricsCommandFactory, log, "metrics"),
		},
		{
			Name:        "autocompletion",
			Usage:       "Enable autocompletion support for bash and fish shells",
			Description: cmdDescriptions["autocompletion"],
			Flags: []cli.Flag{
				cli.StringFlag{
					Name:  "fish-dir",
					Usage: "The name of directory to add fish autocompletion script.",
				},
				cli.BoolFlag{
					Name:  "no-bashrc",
					Usage: "Disable appending autocompletion source command to your bash config file.",
				},
				cli.StringFlag{
					Name:  "bash-dir",
					Usage: "The name of directory to add bash autocompletion script.",
				},
			},
			Action: ctlcli.FactoryAction(
				AutocompleteCommandFactory, log, "autocompletion",
			),
			BashComplete: ctlcli.FactoryCompletion(
				AutocompleteCommandFactory, log, "autocompletion",
			),
		},
		{
			Name: "cp",
			Usage: fmt.Sprintf(
				"Copy a file from one one machine to another",
			),
			Description: cmdDescriptions["cp"],
			Flags: []cli.Flag{
				cli.BoolFlag{
					Name: "debug",
				},
			},
			Action: ctlcli.FactoryAction(
				CpCommandFactory, log, "cp",
			),
			BashComplete: ctlcli.FactoryCompletion(
				CpCommandFactory, log, "cp",
			),
		},
		{
			Name:  "log",
			Usage: "Display logs.",
			Flags: []cli.Flag{
				cli.BoolFlag{Name: "debug", Hidden: true},
				cli.BoolFlag{Name: "no-kd-log"},
				cli.BoolFlag{Name: "no-klient-log"},
				cli.StringFlag{Name: "kd-log-file"},
				cli.StringFlag{Name: "klient-log-file"},
				cli.IntFlag{Name: "lines, n"},
			},
			Action: ctlcli.FactoryAction(LogCommandFactory, log, "log"),
		},
		{
			Name: "open",
			Usage: fmt.Sprintf(
				"Open the given file(s) on the Koding UI",
			),
			Description: cmdDescriptions["open"],
			Flags: []cli.Flag{
				cli.BoolFlag{Name: "debug"},
			},
			Action: ctlcli.FactoryAction(OpenCommandFactory, log, "log"),
		},
	}

	if experimental {
		app.Commands = append(app.Commands,
			cli.Command{
				Name:  "auth",
				Usage: "User authorization.",
				Subcommands: []cli.Command{
					{
						Name:   "login",
						Usage:  "Log in to your kd.io or koding.com account.",
						Action: ctlcli.ExitErrAction(AuthLogin, log, "login"),
						Flags: []cli.Flag{
							cli.BoolFlag{
								Name:  "json",
								Usage: "Output in JSON format.",
							},
							cli.StringFlag{
								Name:  "team",
								Usage: "Specify a Koding team to log in. Leaving empty logs in to kd.io by default.",
							},
							cli.StringFlag{
								Name:  "baseurl",
								Usage: "Specify a Koding endpoint to log in.",
								Value: config.Konfig.Endpoints.Koding.Public.String(),
							},
							cli.StringFlag{
								Name:  "token",
								Usage: "Use temporary token to authenticate to your Koding account.",
							},
						},
					},
					// command: kd auth register
					auth.NewRegisterSubCommand(log),
				},
			},
			cli.Command{
				Name:  "config",
				Usage: "Manage tool configuration.",
				Subcommands: []cli.Command{{
					Name:   "show",
					Usage:  "Show configuration.",
					Action: ctlcli.ExitErrAction(ConfigShow, log, "show"),
					Flags: []cli.Flag{
						cli.BoolFlag{
							Name:  "defaults",
							Usage: "Show also default configuration",
						},
						cli.BoolFlag{
							Name:  "json",
							Usage: "Output in JSON format.",
						},
					},
				}, {
					Name:      "list",
					ShortName: "ls",
					Usage:     "List all available configurations.",
					Action:    ctlcli.ExitErrAction(ConfigList, log, "list"),
					Flags: []cli.Flag{
						cli.BoolFlag{
							Name:  "json",
							Usage: "Output in JSON format.",
						},
					},
				}, {
					Name:   "use",
					Usage:  "Change active configuration.",
					Action: ctlcli.ExitErrAction(ConfigUse, log, "use"),
				}, {
					Name:   "set",
					Usage:  "Set a value for the given key, overwriting default one.",
					Action: ctlcli.ExitErrAction(ConfigSet, log, "set"),
				}, {
					Name:   "unset",
					Usage:  "Unset the given key, restoring the defaut value.",
					Action: ctlcli.ExitErrAction(ConfigUnset, log, "set"),
				}, {
					Name:   "reset",
					Usage:  "Resets configuration to the default value fetched from Koding.",
					Action: ctlcli.ExitErrAction(ConfigReset, log, "reset"),
					Flags: []cli.Flag{
						cli.BoolFlag{
							Name:  "force",
							Usage: "Force retrieving configuration from Koding.",
						},
					},
				}},
			},
			cli.Command{
				Name:      "credential",
				ShortName: "c",
				Usage:     "Manage stack credentials.",
				Subcommands: []cli.Command{{
					Name:      "list",
					ShortName: "ls",
					Usage:     "List imported stack credentials.",
					Action:    ctlcli.ExitErrAction(CredentialList, log, "list"),
					Flags: []cli.Flag{
						cli.BoolFlag{
							Name:  "json",
							Usage: "Output in JSON format.",
						},
						cli.StringFlag{
							Name:  "provider, p",
							Usage: "Specify credential provider.",
						},
						cli.StringFlag{
							Name:  "team",
							Usage: "Specify team which the credential belongs to.",
						},
					},
				}, {
					Name:   "create",
					Usage:  "Create new stack credential.",
					Action: ctlcli.ExitErrAction(CredentialCreate, log, "create"),
					Flags: []cli.Flag{
						cli.BoolFlag{
							Name:  "json",
							Usage: "Output in JSON format.",
						},
						cli.StringFlag{
							Name:  "provider, p",
							Usage: "Specify credential provider.",
						},
						cli.StringFlag{
							Name:  "file, f",
							Value: "",
							Usage: "Read credential from a file.",
						},
						cli.StringFlag{
							Name:  "team",
							Usage: "Specify team which the credential belongs to.",
						},
						cli.StringFlag{
							Name:  "title",
							Usage: "Specify credential title.",
						},
					},
				}, {
					Name:   "use",
					Usage:  "Change default credential per provider.",
					Action: ctlcli.ExitErrAction(CredentialUse, log, "use"),
				}, {
					Name:   "describe",
					Usage:  "Describe credential documents.",
					Action: ctlcli.ExitErrAction(CredentialDescribe, log, "describe"),
					Flags: []cli.Flag{
						cli.BoolFlag{
							Name:  "json",
							Usage: "Output in JSON format.",
						},
						cli.StringFlag{
							Name:  "provider, p",
							Usage: "Specify credential provider.",
						},
					},
				}},
			},
			cli.Command{
				Name:  "machine",
				Usage: "Manage remote machines.",
				Subcommands: []cli.Command{{
					Name:      "list",
					ShortName: "ls",
					Usage:     "List available machines.",
					Action:    ctlcli.ExitErrAction(MachineListCommand, log, "list"),
					Flags: []cli.Flag{
						cli.BoolFlag{
							Name:  "json",
							Usage: "Output in JSON format.",
						},
					},
				}, {
					Name:      "ssh",
					ShortName: "s",
					Usage:     "SSH into provided remote machine.",
					Action:    ctlcli.ExitErrAction(MachineSSHCommand, log, "ssh"),
					Flags: []cli.Flag{
						cli.StringFlag{
							Name:  "username",
							Usage: "Remote machine username.",
						},
					},
				}, {
					Name:      "mount",
					ShortName: "m",
					Usage:     "Mount remote folder to local directory.",
					Action:    ctlcli.ExitErrAction(MachineMountCommand, log, "mount"),
					Flags:     []cli.Flag{},
					Subcommands: []cli.Command{{
						Name:      "list",
						ShortName: "ls",
						Usage:     "List available mounts.",
						Action:    ctlcli.ExitErrAction(MachineListMountCommand, log, "mount list"),
						Flags: []cli.Flag{
							cli.StringFlag{
								Name:  "filter-machine",
								Usage: "Limits the output to all mounts bound to machine ID.",
							},
							cli.StringFlag{
								Name:  "filter-mount",
								Usage: "Limits the output to a specific mount ID.",
							},
							cli.BoolFlag{
								Name:  "json",
								Usage: "Output in JSON format.",
							},
						},
					}},
				}, {
					Name:      "umount",
					ShortName: "u",
					Usage:     "Unmount remote directory.",
					Action:    ctlcli.ExitErrAction(MachineUmountCommand, log, "umount"),
					Flags:     []cli.Flag{},
				}},
			},
			cli.Command{
				Name:  "stack",
				Usage: "Manage stacks.",
				Subcommands: []cli.Command{{
					Name:   "create",
					Usage:  "Create new stack.",
					Action: ctlcli.ExitErrAction(StackCreate, log, "create"),
					Flags: []cli.Flag{
						cli.StringFlag{
							Name:  "provider, p",
							Usage: "Specify stack provider.",
						},
						cli.StringSliceFlag{
							Name:  "credential, c",
							Usage: "Specify stack credentials.",
						},
						cli.StringFlag{
							Name:  "team",
							Usage: "Specify team which the stack belongs to.",
						},
						cli.StringFlag{
							Name:  "file, f",
							Value: "kd.yml",
							Usage: "Read stack template from a file.",
						},
						cli.BoolFlag{
							Name:  "json",
							Usage: "Output in JSON format.",
						},
					},
				}},
			},
			cli.Command{
				Name:  "template",
				Usage: "Manage stack templates.",
				Subcommands: []cli.Command{{
					Name:      "list",
					ShortName: "ls",
					Usage:     "List all stack templates.",
					Action:    ctlcli.ExitErrAction(TemplateList, log, "list"),
					Flags: []cli.Flag{
						cli.BoolFlag{
							Name:  "json",
							Usage: "Output in JSON format.",
						},
						cli.StringFlag{
							Name:  "template, t",
							Usage: "Limit to templates with a given name.",
						},
					},
				}, {
					Name:   "show",
					Usage:  "Show details of a stack template.",
					Action: ctlcli.ExitErrAction(TemplateShow, log, "show"),
					Flags: []cli.Flag{
						cli.StringFlag{
							Name:  "template, t",
							Usage: "Show template with a given name.",
						},
						cli.BoolFlag{
							Name:  "json",
							Usage: "Output in JSON format.",
						},
						cli.StringFlag{
							Name:  "id",
							Usage: "Limit to a template that matches the ID.",
						},
						cli.BoolFlag{
							Name:  "hcl",
							Usage: "Output in HCL format.",
						},
					},
				}, {
					Name:   "delete",
					Usage:  "Delete a stack template.",
					Action: ctlcli.ExitErrAction(TemplateDelete, log, "delete"),
					Flags: []cli.Flag{
						cli.StringFlag{
							Name:  "template, t",
							Usage: "Show template with a given name.",
						},
						cli.StringFlag{
							Name:  "id",
							Usage: "Limit to a template that matches the ID.",
						},
						cli.StringFlag{
							Name:  "force",
							Usage: "Do not ask form confirmation.",
						},
					},
				}},
			},

			cli.Command{
				Name:  "team",
				Usage: "List available teams and set team context.",
				Subcommands: []cli.Command{{
					Name:   "show",
					Usage:  "Shows your currently used team.",
					Action: ctlcli.ExitErrAction(TeamShow, log, "show"),
					Flags: []cli.Flag{
						cli.BoolFlag{
							Name:  "json",
							Usage: "Output in JSON format.",
						},
					},
				}, {
					Name:   "list",
					Usage:  "Lists user's teams.",
					Action: ctlcli.ExitErrAction(TeamList, log, "list"),
					Flags: []cli.Flag{
						cli.StringFlag{
							Name:  "slug",
							Value: "",
							Usage: "Limits the output to the specified team slug",
						},
						cli.BoolFlag{
							Name:  "json",
							Usage: "Output in JSON format.",
						},
					},
				}},
			},
		)
	}

	app.Run(args)
}

// ExitWithMessage takes a ExitingWithMessageCommand type and returns a
// codegansta/cli friendly command Action.
func ExitWithMessage(f ExitingWithMessageCommand, log logging.Logger, cmd string) cli.ActionFunc {
	return func(c *cli.Context) error {
		s, e := f(c, log, cmd)
		if s != "" {
			fmt.Println(s)
		}
		ctlcli.Close()
		os.Exit(e)

		return nil
	}
}
