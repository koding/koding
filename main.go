package main

import (
	"fmt"
	"os"

	"github.com/codegangsta/cli"
)

func main() {
	app := cli.NewApp()
	app.Name = Name
	//app.Usage = ""
	//app.Action = Help
	app.Commands = []cli.Command{
		cli.Command{
			Name:   "list",
			Usage:  "List the available machines",
			Action: Exit(CheckUpdateFirst(ListCommand)),
			Subcommands: []cli.Command{
				cli.Command{
					Name:   "mounts",
					Usage:  "List the available machines",
					Action: Exit(CheckUpdateFirst(MountsCommand)),
				},
			},
		},
		cli.Command{
			Name:        "mount",
			Usage:       "Mount a remote folder to a local folder",
			Description: "Mount a remote folder from the given remote machine, to the specified local folder.",
			Action:      Exit(CheckUpdateFirst(MountCommand)),
		},
		cli.Command{
			Name:        "unmount",
			Usage:       "Unmount specified machine.",
			Description: "Unmount a machine which was previously mounted.",
			Action:      Exit(CheckUpdateFirst(UnmountCommand)),
		},
		cli.Command{
			Name:        "install",
			Usage:       fmt.Sprintf("Install the %s. sudo is required.", KlientName),
			Description: fmt.Sprintf("Install the %s. sudo is required.", KlientName),
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
	return func(c *cli.Context) {
		os.Exit(f(c))
	}
}
