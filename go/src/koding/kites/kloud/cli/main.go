package main

import (
	"fmt"
	"koding/kites/kloud/cli/command"
	"os"

	"github.com/mitchellh/cli"
)

const (
	Version = "0.0.1"
	Name    = "kloudctl"
)

func main() {
	c := &cli.CLI{
		Args: os.Args[1:],
		Commands: map[string]cli.CommandFactory{
			"ping":  command.NewPing(),
			"build": command.NewBuild(),
		},
		HelpFunc: cli.BasicHelpFunc(Name),
	}

	for _, arg := range os.Args {
		if arg == "--version" {
			fmt.Println(Version)
			os.Exit(0)
		}
	}

	_, err := c.Run()
	if err != nil {
		command.DefaultUi.Error(err.Error())
	}
}
