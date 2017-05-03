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
	"os/signal"
	"runtime"

	"koding/klientctl/auth"
	"koding/klientctl/config"
	"koding/klientctl/ctlcli"
	"koding/klientctl/daemon"
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
	"daemon",
}

var signals = []os.Signal{
	os.Interrupt,
	os.Kill,
}

// log is used as a global loggger, for commands like ListCommand that
// need refactoring to support instance based commands.
//
// TODO: Remove this after all commands have been refactored into structs. Ie, the
// cli rewrite.
var log logging.Logger

var debug = os.Getenv("KD_DEBUG") == "1"

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

	kloud.DefaultLog = log
	testKloudHook(kloud.DefaultClient)
	defer ctlcli.Close()

	// TODO(leeola): deprecate this default, instead passing it as a dependency
	// to the users of it.
	//
	// init the defaultHealthChecker with the log.
	defaultHealthChecker = NewDefaultHealthChecker(log)

	// Check if the command the user is giving requires sudo.
	if err := AdminRequired(os.Args, sudoRequiredFor, util.NewPermissions()); err != nil {
		// In the event of an error, simply print the error to the user
		// and exit.
		fmt.Fprintln(os.Stderr, "This command requires sudo.")
		ctlcli.Close()
		os.Exit(10)
	}

	if !daemon.Installed() && !requiresDaemon(os.Args[1:]) {
		fmt.Fprintln(os.Stderr, "This command requires a daemon to be installed. Please install it "+
			"with the following command:\n\n\tsudo kd install\n")
		ctlcli.Close()
		os.Exit(1)
	}

	sig := make(chan os.Signal, 1)

	go func() {
		<-sig
		ctlcli.Close()
		os.Exit(1)
	}()

	signal.Notify(sig, signals...)

	app := cli.NewApp()
	app.Name = config.Name
	app.Version = getReadableVersion(config.VersionNum())
	app.EnableBashCompletion = true

	app.Commands = []cli.Command{{
		Name:  "auth",
		Usage: "User authorization.",
		Subcommands: []cli.Command{{
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
				cli.BoolFlag{
					Name:  "force",
					Usage: "Force new session instead of using existing one.",
				},
			},
		}, {
			Name:   "show",
			Usage:  "Show current session details.",
			Action: ctlcli.ExitErrAction(AuthShow, log, "show"),
			Flags: []cli.Flag{
				cli.BoolFlag{
					Name:  "json",
					Usage: "Output in JSON format.",
				},
			},
		},
			auth.NewRegisterSubCommand(log), // command: kd auth register
		},
	}, {
		Name:  "compat",
		Usage: "Compatibility commands for use with old mounts.",
		Subcommands: []cli.Command{{
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
		}, {
			Name:        "mount",
			ShortName:   "m",
			Usage:       "Mount a remote folder to a local folder.",
			Description: cmdDescriptions["compat-mount"],
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
		}, {
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
		}, {
			Name:            "run",
			Usage:           "Run command on remote or local machine.",
			Description:     cmdDescriptions["run"],
			Action:          ctlcli.ExitAction(RunCommandFactory, log, "run"),
			SkipFlagParsing: true,
		}, {
			Name:   "repair",
			Usage:  "Repair the given mount",
			Action: ctlcli.FactoryAction(RepairCommandFactory, log, "repair"),
		}, {
			Name: "cp",
			Usage: fmt.Sprintf(
				"Copy a file from one one machine to another",
			),
			Description: cmdDescriptions["compat-cp"],
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
		}, {
			Name:        "unmount",
			ShortName:   "u",
			Usage:       "Unmount previously mounted machine.",
			Description: cmdDescriptions["compat-unmount"],
			Action:      ctlcli.FactoryAction(UnmountCommandFactory, log, "unmount"),
		}, {
			Name:        "remount",
			ShortName:   "r",
			Usage:       "Remount previously mounted machine using same settings.",
			Description: cmdDescriptions["remount"],
			Action:      ctlcli.ExitAction(RemountCommandFactory, log, "remount"),
		}},
	}, {
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
	}, {
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
			Name:   "init",
			Usage:  "Create a credential file.",
			Action: ctlcli.ExitErrAction(CredentialInit, log, "init"),
			Flags: []cli.Flag{
				cli.StringFlag{
					Name:  "provider, p",
					Usage: "Specify credential provider.",
				},
				cli.StringFlag{
					Name:  "output, o",
					Value: "credential.json",
					Usage: "Output credential file.",
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
	}, {
		Name:  "daemon",
		Usage: "Manage KD Daemon service.",
		Subcommands: []cli.Command{{
			Name:   "install",
			Usage:  "Install the daemon and dependencies.",
			Action: ctlcli.ExitErrAction(DaemonInstall, log, "install"),
			Flags: []cli.Flag{
				cli.BoolFlag{
					Name:  "force, f",
					Usage: "Forces execution of all installation steps.",
				},
				cli.StringFlag{
					Name:  "prefix",
					Usage: "Overwrite installation directory.",
				},
				cli.StringFlag{
					Name:  "baseurl",
					Usage: "Specify a Koding endpoint to log in.",
					Value: config.Konfig.Endpoints.Koding.Public.String(),
				},
				cli.StringFlag{
					Name:  "token",
					Usage: "Temporary token to logging in into your Koding account.",
				},
				cli.StringFlag{
					Name:  "team",
					Usage: "Provide explicit Koding team to log into.",
				},
				cli.StringSliceFlag{
					Name:  "skip",
					Usage: "List steps to skip during installation.",
				},
			},
		}, {
			Name:   "uninstall",
			Usage:  "Uninstall the daemon and dependencies.",
			Action: ctlcli.ExitErrAction(DaemonUninstall, log, "uninstall"),
			Flags: []cli.Flag{
				cli.BoolFlag{
					Name:  "force, f",
					Usage: "Forces execution of all uninstallation steps.",
				},
			},
		}, {
			Name:   "update",
			Usage:  "Update KD and KD Daemon to the latest versions.",
			Action: ctlcli.ExitErrAction(DaemonUpdate, log, "update"),
			Flags: []cli.Flag{
				cli.BoolFlag{
					Name:  "force",
					Usage: "Force retrieving configuration from Koding.",
				},
				// TODO(rjeczalik): Left here for compatibility reasons, remove in future.
				cli.BoolFlag{
					Name:   "continue",
					Usage:  "Internal use only.",
					Hidden: true,
				},
			},
		}, {
			Name:   "start",
			Usage:  "Start the daemon service.",
			Action: ctlcli.ExitErrAction(DaemonStart, log, "start"),
		}, {
			Name:   "restart",
			Usage:  "Restart the daemon service.",
			Action: ctlcli.ExitErrAction(DaemonRestart, log, "restart"),
		}, {
			Name:   "stop",
			Usage:  "Stop the daemon service.",
			Action: ctlcli.ExitErrAction(DaemonStop, log, "stop"),
		}},
	}, {
		Name:   "init",
		Usage:  "Initializes KD project.",
		Action: ctlcli.ExitErrAction(Init, log, "init"),
	}, {
		Name:        "version",
		Usage:       "Display version information.",
		HideHelp:    true,
		Description: cmdDescriptions["version"],
		Action:      ctlcli.ExitAction(VersionCommand, log, "version"),
		Flags: []cli.Flag{
			cli.BoolFlag{
				Name:  "json",
				Usage: "Output in JSON format.",
			},
		},
	}, {
		Name:        "status",
		Usage:       fmt.Sprintf("Check status of the %s.", config.KlientName),
		Description: cmdDescriptions["status"],
		Action:      ctlcli.ExitAction(StatusCommand, log, "status"),
	}, {
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
	}, {
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
		Subcommands: []cli.Command{{
			Name:   "upload",
			Usage:  "Share a text file.",
			Action: ctlcli.ExitErrAction(LogUpload, log, "upload"),
		}},
	}, {
		Name: "open",
		Usage: fmt.Sprintf(
			"Open the given file(s) on the Koding UI",
		),
		Description: cmdDescriptions["open"],
		Flags: []cli.Flag{
			cli.BoolFlag{Name: "debug"},
		},
		Action: ctlcli.FactoryAction(OpenCommandFactory, log, "log"),
	}, {
		Name:         "machine",
		Usage:        "Manage remote machines.",
		BashComplete: func(c *cli.Context) {},
		Subcommands: []cli.Command{{
			Name:         "list",
			ShortName:    "ls",
			Usage:        "List available machines.",
			Action:       ctlcli.ExitErrAction(MachineListCommand, log, "list"),
			BashComplete: func(c *cli.Context) {},
			Flags: []cli.Flag{
				cli.BoolFlag{
					Name:  "json",
					Usage: "Output in JSON format.",
				},
			},
		}, {
			Name:         "ssh",
			ShortName:    "s",
			Usage:        "SSH into provided remote machine.",
			Action:       ctlcli.ExitErrAction(MachineSSHCommand, log, "ssh"),
			BashComplete: func(c *cli.Context) {},
			Flags: []cli.Flag{
				cli.StringFlag{
					Name:  "username",
					Usage: "Remote machine username.",
				},
			},
		}, {
			Name:  "config",
			Usage: "Manage remote machine configuration.",
			Subcommands: []cli.Command{{
				Name:   "set",
				Usage:  "Set a value for a given key.",
				Action: ctlcli.ExitErrAction(MachineConfigSet, log, "set"),
			}, {
				Name:   "show",
				Usage:  "Show configuration.",
				Action: ctlcli.ExitErrAction(MachineConfigShow, log, "show"),
				Flags: []cli.Flag{
					cli.BoolFlag{
						Name:  "json",
						Usage: "Output in JSON format.",
					},
				},
			}},
		}, {
			Name:         "mount",
			Aliases:      []string{"m"},
			Usage:        "Mount remote directory.",
			Description:  cmdDescriptions["mount"],
			Action:       ctlcli.ExitErrAction(MachineMountCommand, log, "mount"),
			BashComplete: func(c *cli.Context) {},
			Flags:        []cli.Flag{},
			Subcommands: []cli.Command{{
				Name:    "list",
				Aliases: []string{"ls"},
				Usage:   "List available mounts.",
				Action:  ctlcli.ExitErrAction(MachineListMountCommand, log, "mount list"),
				Flags: []cli.Flag{
					cli.StringFlag{
						Name:  "filter",
						Usage: "Limits the output to a specific `<mount-id>`.",
					},
					cli.BoolFlag{
						Name:  "json",
						Usage: "Output in JSON format.",
					},
				},
			}, {
				Name:   "inspect",
				Hidden: true,
				Usage:  "Advanced utilities for mount command.",
				Action: ctlcli.ExitErrAction(MachineInspectMountCommand, log, "mount inspect"),
				Flags: []cli.Flag{
					cli.BoolFlag{
						Name:  "sync",
						Usage: "Displays syncing history up to 100 records.",
					},
					cli.BoolFlag{
						Name:  "tree",
						Usage: "Displays the entire mount index tree.",
					},
				},
			}},
		}, {
			Name:         "umount",
			ShortName:    "u",
			Usage:        "Unmount remote directory.",
			Description:  cmdDescriptions["umount"],
			Action:       ctlcli.ExitErrAction(MachineUmountCommand, log, "umount"),
			BashComplete: func(c *cli.Context) {},
			Flags: []cli.Flag{
				cli.BoolFlag{
					Name:  "force, f",
					Usage: "Forces execution of all unmounting steps.",
				},
				cli.BoolFlag{
					Name:  "all, a",
					Usage: "Unmount all mounts.",
				},
			},
		}, {
			Name:            "exec",
			ShortName:       "e",
			Description:     cmdDescriptions["exec"],
			Usage:           "Run a command in a started machine.",
			Action:          ctlcli.ExitErrAction(MachineExecCommand, log, "exec"),
			BashComplete:    func(c *cli.Context) {},
			SkipFlagParsing: true,
		}, {
			Name:            "cp",
			Description:     cmdDescriptions["cp"],
			Usage:           "Copies a file between hosts on a network.",
			Action:          ctlcli.ExitErrAction(MachineCpCommand, log, "cp"),
			SkipFlagParsing: true,
			BashComplete:    func(c *cli.Context) {},
			Flags:           []cli.Flag{},
		}, {
			Name:   "start",
			Usage:  "Start a remove vm given by the <machine ID> | <alias> | <slug>.",
			Action: ctlcli.ExitErrAction(MachineStart, log, "start"),
			Flags: []cli.Flag{
				cli.BoolFlag{
					Name:  "json",
					Usage: "Output in JSON format.",
				},
			},
		}, {
			Name:   "stop",
			Usage:  "Stop a remove vm given by the <machine ID> | <alias> | <slug>.",
			Action: ctlcli.ExitErrAction(MachineStop, log, "stop"),
			Flags: []cli.Flag{
				cli.BoolFlag{
					Name:  "json",
					Usage: "Output in JSON format.",
				},
			},
		}},
	}, {
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
					Value: config.Konfig.Template.File,
					Usage: "Read stack template from a file.",
				},
				cli.BoolFlag{
					Name:  "json",
					Usage: "Output in JSON format.",
				},
			},
		}, {
			Name:      "list",
			ShortName: "ls",
			Usage:     "List all stacks.",
			Action:    ctlcli.ExitErrAction(StackList, log, "list"),
			Flags: []cli.Flag{
				cli.BoolFlag{
					Name:  "json",
					Usage: "Output in JSON format.",
				},
				cli.StringFlag{
					Name:  "team",
					Usage: "Limit to stack for the given team.",
				},
			},
		}},
	}, {
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
		}, {
			Name:   "whoami",
			Usage:  "Displays current authentication details.",
			Action: ctlcli.ExitErrAction(TeamWhoami, log, "whoami"),
			Flags: []cli.Flag{
				cli.BoolFlag{
					Name:  "json",
					Usage: "Output in JSON format.",
				},
			},
		}, {
			Name:   "use",
			Usage:  "Switch team context.",
			Action: ctlcli.ExitErrAction(TeamUse, log, "use"),
		}},
	}, {
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
					Usage: "Limit to templates with the given name.",
				},
				cli.StringFlag{
					Name:  "team",
					Usage: "Limit to templates for the given team.",
				},
			},
		}, {
			Name:   "show",
			Usage:  "Show details of a stack template.",
			Action: ctlcli.ExitErrAction(TemplateShow, log, "show"),
			Flags: []cli.Flag{
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
		}, {
			Name:   "init",
			Usage:  "Generate a new stack template file.",
			Action: ctlcli.ExitErrAction(TemplateInit, log, "init"),
			Flags: []cli.Flag{
				cli.StringFlag{
					Name:  "output, o",
					Usage: "Output template file.",
					Value: config.Konfig.Template.File,
				},
				cli.BoolFlag{
					Name:  "defaults",
					Usage: "Use default values for stack variables.",
				},
				cli.StringFlag{
					Name:  "provider, p",
					Usage: "Cloud provider to use.",
				},
			},
		}},
	}}

	// Alias commands.
	app.Commands = append(app.Commands,
		find(app.Commands, "machine", "list"),
		find(app.Commands, "machine", "ssh"),
		find(app.Commands, "machine", "mount"),
		find(app.Commands, "machine", "umount"),
		find(app.Commands, "machine", "exec"),
		find(app.Commands, "machine", "cp"),
		find(app.Commands, "daemon", "install"),
		find(app.Commands, "daemon", "uninstall"),
		find(app.Commands, "daemon", "update"),
		find(app.Commands, "daemon", "start"),
		find(app.Commands, "daemon", "stop"),
		find(app.Commands, "daemon", "restart"),
	)

	app.Commands = wrapActions(app.Commands)
	app.Run(args)
}

func wrapActions(commands []cli.Command) []cli.Command {
	for i, command := range commands {
		if command.Action != nil {
			commands[i].Action = createActionFunc(command.Action.(cli.ActionFunc))
		}
		if len(command.Subcommands) > 0 {
			commands[i].Subcommands = wrapActions(command.Subcommands)
		}
	}
	return commands
}

func createActionFunc(action cli.ActionFunc) cli.ActionFunc {
	return func(c *cli.Context) error {
		// do things before for c.Command.FullName()
		err := action(c)
		// do things after for the command.
		return err
	}
}

func find(cmds cli.Commands, names ...string) cli.Command {
	last := len(names) - 1

	for _, name := range names[:last] {
		for _, cmd := range cmds {
			if cmd.Name == name {
				cmds = cmd.Subcommands
				break
			}
		}
	}

	for _, cmd := range cmds {
		if cmd.Name == names[last] {
			return cmd
		}
	}

	return cli.Command{}
}

func requiresDaemon(args []string) bool {
	var cmd string
	switch len(args) {
	case 0:
		return false
	case 1:
		cmd = args[0]
	default:
		cmd = args[0]
		if cmd == "daemon" {
			cmd = args[1]
		}
	}

	switch cmd {
	case "config", "version", "auth", "install", "uninstall", "-version":
		return true
	default:
		return false
	}
}
