package main

import (
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
			Action: Exit(CheckUpdateFirst(ListCommand)),
			Subcommands: []cli.Command{
				cli.Command{
					Name:   "mounts",
					Action: Exit(CheckUpdateFirst(MountsCommand)),
				},
			},
		},
		cli.Command{
			Name:   "mount",
			Action: Exit(CheckUpdateFirst(MountCommand)),
		},
		cli.Command{
			Name:   "unmount",
			Action: Exit(CheckUpdateFirst(UnmountCommand)),
		},
		cli.Command{
			Name:   "install",
			Action: Exit(InstallCommand),
		},
		cli.Command{
			Name:   "uninstall",
			Action: Exit(UninstallCommand),
		},
		cli.Command{
			Name:   "start",
			Action: Exit(StartCommand),
		},
		cli.Command{
			Name:   "stop",
			Action: Exit(StopCommand),
		},
		cli.Command{
			Name:   "update",
			Action: Exit(UpdateCommand),
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
