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
		cli.StringFlag{"kontrol, k", "https://kontrol.koding.com", "Kontrol url for query"},
	}
	app.Commands = []cli.Command{
		command.BuildCommand(),
	}
	app.Before = func(c *cli.Context) error {
		return nil
	}

	app.Run(os.Args)
}
