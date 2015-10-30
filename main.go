package main

import (
	"fmt"
	"os"

	"github.com/codegangsta/cli"
	"github.com/koding/klient/cmd/klientctl/util"
)

// sudoRequiredFor is the default list of commands that require sudo.
// The actual handling of this list is done in the SudoRequired func.
var sudoRequiredFor = []string{
	"install",
	"uninstall",
	"start",
	"stop",
	"update",
}

func main() {
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
			Name:   "list",
			Usage:  "List the available machines.",
			Action: Exit(CheckUpdateFirst(ListCommand)),
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
				// TODO: implement this in klient and then enable this
				// cli.StringFlag{
				//   Name:  "watch, w",
				//   Usage: "Enable watching for changes in remote machine.",
				// },
			},
			Action: Exit(CheckUpdateFirst(MountCommand)),
		},
		cli.Command{
			Name:        "unmount",
			Usage:       "Unmount previously mounted machine.",
			Description: cmdDescriptions["unmount"],
			Action:      Exit(CheckUpdateFirst(UnmountCommand)),
		},
		cli.Command{
			Name:        "ssh",
			Usage:       "SSH into the machine.",
			Description: cmdDescriptions["ssh"],
			Action:      Exit(CheckUpdateFirst(SSHCommandFactory)),
		},
		cli.Command{
			Name:        "install",
			Usage:       fmt.Sprintf("Install the %s. sudo is required.", KlientName),
			Description: cmdDescriptions["install"],
			Flags: []cli.Flag{
				cli.StringFlag{
					Name:  "kontrol, k",
					Usage: "Specify an alternate Kontrol",
				},
			},
			//HideHelp: true,
			Action: Exit(InstallCommand),
		},
		cli.Command{
			Name:        "uninstall",
			Usage:       fmt.Sprintf("Uninstall the %s. sudo is required.", KlientName),
			Description: fmt.Sprintf("Uninstall the %s. sudo is required.", KlientName),
			Action:      Exit(UninstallCommand),
		},
		cli.Command{
			Name:        "status",
			Usage:       fmt.Sprintf("Status of the %s.", KlientName),
			Description: fmt.Sprintf("Status the %s.", KlientName),
			Action:      Exit(StatusCommand),
		},
		cli.Command{
			Name:        "start",
			Usage:       fmt.Sprintf("Start the %s. sudo is required.", KlientName),
			Description: fmt.Sprintf("Start the %s. sudo is required.", KlientName),
			Action:      Exit(StartCommand),
		},
		cli.Command{
			Name:        "stop",
			Usage:       fmt.Sprintf("Stop the %s. sudo is required.", KlientName),
			Description: fmt.Sprintf("Stop the %s. sudo is required.", KlientName),
			Action:      Exit(StopCommand),
		},
		cli.Command{
			Name:        "restart",
			Usage:       fmt.Sprintf("Restart the %s. sudo is required.", KlientName),
			Description: fmt.Sprintf("Restart the %s. sudo is required.", KlientName),
			Action:      Exit(RestartCommand),
		},
		cli.Command{
			Name:        "update",
			Usage:       "Update to latest version. sudo is required.",
			Description: "Update to latest version. sudo is required.",
			Action:      Exit(UpdateCommand),
		},
	}

	app.Run(os.Args)
}

type ExitingCommand func(*cli.Context) int

func Exit(f ExitingCommand) func(*cli.Context) {
	return func(c *cli.Context) { os.Exit(f(c)) }
}
