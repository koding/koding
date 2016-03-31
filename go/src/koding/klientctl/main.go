package main

import (
	"fmt"
	"io"
	"io/ioutil"
	"os"

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

	// Create our logger.
	//
	// TODO: Single commit temporary solution, need to remove the above logger
	// in favor of this.
	log = logging.NewLogger("kd")
	log.SetHandler(logging.NewWriterHandler(logWriter))
	log.Info("kd binary called with: %s", os.Args)

	// Check if the command the user is giving requires sudo.
	if err := AdminRequired(os.Args, sudoRequiredFor, util.NewPermissions()); err != nil {
		// In the event of an error, simply print the error to the user
		// and exit.
		fmt.Println("Error: this command requires sudo.")
		os.Exit(10)
	}

	app := cli.NewApp()
	app.Name = config.Name
	app.Version = fmt.Sprintf("%d", config.Version)

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
			},
			Subcommands: []cli.Command{
				cli.Command{
					Name:   "mounts",
					Usage:  "List the mounted machines.",
					Action: ctlcli.ExitAction(CheckUpdateFirst(MountsCommand, log, "mounts")),
				},
			},
		},
		cli.Command{
			Name:        "mount",
			ShortName:   "m",
			Usage:       "Mount a remote folder to a local folder.",
			Description: cmdDescriptions["mount"],
			Flags: []cli.Flag{
				cli.StringFlag{
					Name:  "remotepath, r",
					Usage: "Full path of remote folder in machine to mount to local.",
				},
				cli.BoolFlag{
					Name:  "noignore, i",
					Usage: "Retrieve all files and folders, including ignored folders like .git & .svn.",
				},
				cli.BoolFlag{
					Name:  "noprefetch-meta, p",
					Usage: "Retrieve only top level folder/files. Rest is fetched on request (fastest).",
				},
				cli.BoolFlag{
					Name:  "nowatch, w",
					Usage: "Disable watching for changes on remote machine.",
				},
				cli.BoolFlag{
					Name:  "prefetch-all, a",
					Usage: "Prefetch all contents of the remote directory up front (best performance/slow bootup).",
				},
				cli.IntFlag{
					Name:  "prefetch-interval",
					Usage: "Sets how frequently folder will sync with remote, in seconds. Zero disables syncing.",
				},
			},
			Action: ctlcli.FactoryAction(MountCommandFactory, log, "mount"),
		},
		cli.Command{
			Name:        "unmount",
			ShortName:   "u",
			Usage:       "Unmount previously mounted machine.",
			Description: cmdDescriptions["unmount"],
			Action:      ctlcli.FactoryAction(UnmountCommandFactory, log, "unmount"),
		},
		cli.Command{
			Name:        "ssh",
			ShortName:   "s",
			Usage:       "SSH into the machine.",
			Description: cmdDescriptions["ssh"],
			Action:      ctlcli.ExitAction(CheckUpdateFirst(SSHCommandFactory, log, "ssh")),
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
			//HideHelp: true,
			Action: ctlcli.ExitAction(InstallCommandFactory, log, "install"),
		},
		cli.Command{
			Name:        "uninstall",
			Usage:       fmt.Sprintf("Uninstall the %s.", config.KlientName),
			Description: cmdDescriptions["uninstall"],
			Action:      ExitWithMessage(UninstallCommand, log, "uninstall"),
		},
		cli.Command{
			Name:        "status",
			Usage:       fmt.Sprintf("Check status of the %s.", config.KlientName),
			Description: cmdDescriptions["status"],
			Action:      ctlcli.ExitAction(StatusCommand, log, "status"),
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
			Name:        "restart",
			Usage:       fmt.Sprintf("Restart the %s.", config.KlientName),
			Description: cmdDescriptions["restart"],
			Action:      ctlcli.ExitAction(RestartCommand, log, "restart"),
		},
		cli.Command{
			Name:        "update",
			Usage:       fmt.Sprintf("Update %s to latest version.", config.KlientName),
			Description: cmdDescriptions["update"],
			Action:      ctlcli.ExitAction(UpdateCommand, log, "update"),
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
			Name:     "metrics",
			Usage:    fmt.Sprintf("Internal use only."),
			HideHelp: true,
			Action:   ctlcli.ExitAction(MetricsCommandFactory, log, "metrics"),
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
