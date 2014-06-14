package main

import (
	"koding/kites/kloud/cli/command"
	"os"

	"github.com/codegangsta/cli"
)

const (
	Version = "0.0.1"
)

func main() {
	app := cli.NewApp()
	app.Name = "kloudctl"
	app.Version = Version
	app.Usage = "Command line client for kloud"
	app.Flags = []cli.Flag{
		cli.BoolFlag{"debug", "enable debug mode"},
	}
	app.Commands = []cli.Command{
		command.BuildCommand(),
	}
	app.Run(os.Args)
}
