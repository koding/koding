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

	"koding/klientctl/config"
	"koding/klientctl/ctlcli"
	"koding/klientctl/util"

	"github.com/koding/logging"

	"github.com/codegangsta/cli"
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

func main() {
	// For forward-compatibility with go1.5+, where GOMAXPROCS is
	// always set to a number of available cores.
	runtime.GOMAXPROCS(runtime.NumCPU())

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
		// TODO: Does defer get triggered on os.Exit? I think main() needs to be moved
		// to an alternate func that we can actuall use defer. Eg, main() calls Main(),
		// or something.
		defer f.Close()
		logWriter = f
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

	// Check if the command the user is giving requires sudo.
	if err := AdminRequired(os.Args, sudoRequiredFor, util.NewPermissions()); err != nil {
		// In the event of an error, simply print the error to the user
		// and exit.
		fmt.Println("Error: this command requires sudo.")
		os.Exit(10)
	}

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
		cli.Command{
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
				cli.Command{
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
		cli.Command{
			Name:        "version",
			Usage:       "Display version information.",
			HideHelp:    true,
			Description: cmdDescriptions["version"],
			Action:      ctlcli.ExitAction(VersionCommand, log, "version"),
		},
		cli.Command{
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
				cli.BoolFlag{
					Name:  "debug, d",
					Usage: "Turn on debug logs.",
				},
			},
			Action: ctlcli.FactoryAction(MountCommandFactory, log, "mount"),
			BashComplete: ctlcli.FactoryCompletion(
				MountCommandFactory, log, "mount",
			),
		},
		cli.Command{
			Name:        "unmount",
			ShortName:   "u",
			Usage:       "Unmount previously mounted machine.",
			Description: cmdDescriptions["unmount"],
			Action:      ctlcli.FactoryAction(UnmountCommandFactory, log, "unmount"),
		},
		cli.Command{
			Name:        "remount",
			ShortName:   "r",
			Usage:       "Remount previously mounted machine using same settings.",
			Description: cmdDescriptions["remount"],
			Action:      ctlcli.ExitAction(RemountCommandFactory, log, "remount"),
		},
		cli.Command{
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
		cli.Command{
			Name:            "run",
			Usage:           "Run command on remote or local machine.",
			Description:     cmdDescriptions["run"],
			Action:          ctlcli.ExitAction(RunCommandFactory, log, "run"),
			SkipFlagParsing: true,
		},
		cli.Command{
			Name:   "repair",
			Usage:  "Repair the given mount",
			Action: ctlcli.FactoryAction(RepairCommandFactory, log, "repair"),
		},
		cli.Command{
			Name:        "status",
			Usage:       fmt.Sprintf("Check status of the %s.", config.KlientName),
			Description: cmdDescriptions["status"],
			Action:      ctlcli.ExitAction(StatusCommand, log, "status"),
		},
		cli.Command{
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
			},
		},
		cli.Command{
			Name:        "restart",
			Usage:       fmt.Sprintf("Restart the %s.", config.KlientName),
			Description: cmdDescriptions["restart"],
			Action:      ctlcli.ExitAction(RestartCommand, log, "restart"),
		},
		cli.Command{
			Name:        "start",
			Usage:       fmt.Sprintf("Start the %s.", config.KlientName),
			Description: cmdDescriptions["start"],
			Action:      ctlcli.ExitAction(StartCommand, log, "start"),
		},
		cli.Command{
			Name:        "stop",
			Usage:       fmt.Sprintf("Stop the %s.", config.KlientName),
			Description: cmdDescriptions["stop"],
			Action:      ctlcli.ExitAction(StopCommand, log, "stop"),
		},
		cli.Command{
			Name:        "uninstall",
			Usage:       fmt.Sprintf("Uninstall the %s.", config.KlientName),
			Description: cmdDescriptions["uninstall"],
			Action:      ExitWithMessage(UninstallCommand, log, "uninstall"),
		},
		cli.Command{
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
		cli.Command{
			Name:     "metrics",
			Usage:    fmt.Sprintf("Internal use only."),
			HideHelp: true,
			Action:   ctlcli.ExitAction(MetricsCommandFactory, log, "metrics"),
		},
		cli.Command{
			Name: "autocompletion",
			Usage: fmt.Sprintf(
				"Enable autocompletion support for bash and fish shells",
			),
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
		cli.Command{
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
		cli.Command{
			Name: "log",
			Flags: []cli.Flag{
				cli.BoolFlag{Name: "debug"},
				cli.BoolFlag{Name: "no-kd-log"},
				cli.BoolFlag{Name: "no-klient-log"},
				cli.StringFlag{Name: "kd-log-file"},
				cli.StringFlag{Name: "klient-log-file"},
				cli.IntFlag{Name: "lines, n"},
			},
			Action: ctlcli.FactoryAction(LogCommandFactory, log, "log"),
		},
	}

	app.Run(os.Args)
}

// ExitWithMessage takes a ExitingWithMessageCommand type and returns a
// codegansta/cli friendly command Action.
func ExitWithMessage(f ExitingWithMessageCommand, log logging.Logger, cmd string) func(*cli.Context) {
	return func(c *cli.Context) {
		s, e := f(c, log, cmd)
		if s != "" {
			fmt.Println(s)
		}
		os.Exit(e)
	}
}
