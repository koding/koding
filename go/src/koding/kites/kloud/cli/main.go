package main

import (
	"koding/kites/kloud/cli/command"
	"os"

	"github.com/mitchellh/cli"
)

const (
	Version = "0.0.1"
	Name    = "kloudctl"
)

func main() {
	c := cli.NewCLI(Name, Version)
	c.Args = os.Args[1:]
	c.Commands = map[string]cli.CommandFactory{
		"ping":  command.NewPing(),
		"build": command.NewBuild(),
	}

	_, err := c.Run()
	if err != nil {
		command.DefaultUi.Error(err.Error())
	}
}
