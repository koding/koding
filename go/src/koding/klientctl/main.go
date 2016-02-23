package main

import (
	"fmt"
	"io"
	"io/ioutil"
	"os"

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
	app.Name = Name
	app.Version = fmt.Sprintf("%d", Version)

	app.Commands = []cli.Command{
		cli.Command{
			Name:      "list",
			ShortName: "ls",
			Usage:     "List running machines for user.",
			Action:    ExitAction(CheckUpdateFirst(ListCommand, log, "list")),
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
					Action: ExitAction(CheckUpdateFirst(MountsCommand, log, "mounts")),
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
					Usage: "Full path of remote folder in machine to mount.",
				},
				cli.BoolFlag{
					Name:  "noignore, i",
					Usage: "Disable ignoring of default remote folders.",
				},
				cli.BoolFlag{
					Name:  "noprefetch-meta, p",
					Usage: "Disable prefetching of folder metadata.",
				},
				cli.BoolFlag{
					Name:  "nowatch, w",
					Usage: "Disable watching for changes on remote machine.",
				},
				cli.BoolFlag{
					Name:  "prefetch-all, a",
					Usage: "Enable prefetching contents of the remote directory.",
				},
				cli.IntFlag{
					Name:  "prefetch-interval",
					Usage: "Sets how frequently folder will sync with remote, in seconds. Zero disables syncing.",
				},
			},
			Action: FactoryAction(MountCommandFactory, log, "mount"),
		},
		cli.Command{
			Name:        "unmount",
			ShortName:   "u",
			Usage:       "Unmount previously mounted machine.",
			Description: cmdDescriptions["unmount"],
			Action:      FactoryAction(UnmountCommandFactory, log, "unmount")},
		cli.Command{
			Name:        "ssh",
			ShortName:   "s",
			Usage:       "SSH into the machine.",
			Description: cmdDescriptions["ssh"],
			Action:      ExitAction(CheckUpdateFirst(SSHCommandFactory, log, "ssh")),
		},
		cli.Command{
			Name:        "install",
			Usage:       fmt.Sprintf("Install the %s.", KlientName),
			Description: cmdDescriptions["install"],
			Flags: []cli.Flag{
				cli.StringFlag{
					Name:  "kontrol, k",
					Usage: "Specify an alternate Kontrol",
				},
			},
			//HideHelp: true,
			Action: ExitAction(InstallCommandFactory, log, "install"),
		},
		cli.Command{
			Name:        "uninstall",
			Usage:       fmt.Sprintf("Uninstall the %s.", KlientName),
			Description: cmdDescriptions["uninstall"],
			Action:      ExitWithMessage(UninstallCommand, log, "uninstall"),
		},
		cli.Command{
			Name:        "status",
			Usage:       fmt.Sprintf("Check status of the %s.", KlientName),
			Description: cmdDescriptions["status"],
			Action:      ExitAction(StatusCommand, log, "status"),
		},
		cli.Command{
			Name:        "start",
			Usage:       fmt.Sprintf("Start the %s.", KlientName),
			Description: cmdDescriptions["start"],
			Action:      ExitAction(StartCommand, log, "start"),
		},
		cli.Command{
			Name:        "stop",
			Usage:       fmt.Sprintf("Stop the %s.", KlientName),
			Description: cmdDescriptions["stop"],
			Action:      ExitAction(StopCommand, log, "stop"),
		},
		cli.Command{
			Name:        "restart",
			Usage:       fmt.Sprintf("Restart the %s.", KlientName),
			Description: cmdDescriptions["restart"],
			Action:      ExitAction(RestartCommand, log, "restart"),
		},
		cli.Command{
			Name:        "update",
			Usage:       fmt.Sprintf("Update %s to latest version.", KlientName),
			Description: cmdDescriptions["update"],
			Action:      ExitAction(UpdateCommand, log, "update"),
		},
		cli.Command{
			Name:            "run",
			Usage:           "Run command on remote or local machine.",
			Description:     cmdDescriptions["run"],
			Action:          ExitAction(RunCommandFactory, log, "run"),
			SkipFlagParsing: true,
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
