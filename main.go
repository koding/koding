package main

import (
	"fmt"
	"io"
	"io/ioutil"
	"os"

	"github.com/codegangsta/cli"
	"github.com/koding/klientctl/logging"
	"github.com/koding/klientctl/util"
)

// ExitingCommand is a function that returns an exit code
type ExitingCommand func(*cli.Context) int

// ExitingWithMessageCommand is a function which prints the given message to
// Stdout. Useful for printig a message to the user in a convenient single-use way.
type ExitingWithMessageCommand func(*cli.Context) (string, int)

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

	// Create our logger instance.
	log = logging.NewLogger("kd")
	log.SetHandler(logging.NewWriterHandler(logWriter))
	log.Infof("kd binary called with: %s", os.Args)

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
			Usage:     "List the available machines.",
			Action:    Exit(CheckUpdateFirst(ListCommand)),
			Subcommands: []cli.Command{
				cli.Command{
					Name:   "mounts",
					Usage:  "List the mounted machines.",
					Action: Exit(CheckUpdateFirst(MountsCommand)),
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
					Name:  "noignore, n",
					Usage: "Disable ignoring of default remote folders.",
				},
				cli.BoolFlag{
					Name:  "noprefetch, p",
					Usage: "Disable prefetching of folder metadata on mount.",
				},
				cli.BoolFlag{
					Name:  "nowatch, w",
					Usage: "Disable watching for changes on remote machine.",
				},
			},
			Action: Exit(CheckUpdateFirst(MountCommand)),
		},
		cli.Command{
			Name:        "unmount",
			ShortName:   "u",
			Usage:       "Unmount previously mounted machine.",
			Description: cmdDescriptions["unmount"],
			Action:      Exit(CheckUpdateFirst(UnmountCommand)),
		},
		cli.Command{
			Name:        "ssh",
			ShortName:   "s",
			Usage:       "SSH into the machine.",
			Description: cmdDescriptions["ssh"],
			Action:      Exit(CheckUpdateFirst(SSHCommandFactory)),
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
			Action: Exit(InstallCommandFactory),
		},
		cli.Command{
			Name:        "uninstall",
			Usage:       fmt.Sprintf("Uninstall the %s.", KlientName),
			Description: fmt.Sprintf("Uninstall the %s.", KlientName),
			Action:      ExitWithMessage(UninstallCommand),
		},
		cli.Command{
			Name:        "status",
			Usage:       fmt.Sprintf("Status of the %s.", KlientName),
			Description: fmt.Sprintf("Status the %s.", KlientName),
			Action:      Exit(StatusCommand),
		},
		cli.Command{
			Name:        "start",
			Usage:       fmt.Sprintf("Start the %s.", KlientName),
			Description: fmt.Sprintf("Start the %s.", KlientName),
			Action:      Exit(StartCommand),
		},
		cli.Command{
			Name:        "stop",
			Usage:       fmt.Sprintf("Stop the %s.", KlientName),
			Description: fmt.Sprintf("Stop the %s.", KlientName),
			Action:      Exit(StopCommand),
		},
		cli.Command{
			Name:        "restart",
			Usage:       fmt.Sprintf("Restart the %s.", KlientName),
			Description: fmt.Sprintf("Restart the %s.", KlientName),
			Action:      Exit(RestartCommand),
		},
		cli.Command{
			Name:        "update",
			Usage:       "Update to latest version.",
			Description: "Update to latest version.",
			Action:      Exit(UpdateCommand),
		},
		cli.Command{
			Name:            "run",
			Usage:           "Run command on remote or local machine.",
			Description:     cmdDescriptions["run"],
			Action:          Exit(RunCommandFactory),
			SkipFlagParsing: true,
		},
	}

	app.Run(os.Args)
}

// Exit is a wrapper around commands to return to proper error code.
func Exit(f ExitingCommand) func(*cli.Context) {
	return func(c *cli.Context) { os.Exit(f(c)) }
}

// ExitWithMessage takes a ExitingWithMessageCommand type and returns a
// codegansta/cli friendly command Action.
func ExitWithMessage(f ExitingWithMessageCommand) func(*cli.Context) {
	return func(c *cli.Context) {
		s, e := f(c)
		if s != "" {
			fmt.Println(s)
		}
		os.Exit(e)
	}
}
