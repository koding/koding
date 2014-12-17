package main

import (
	"os"

	"koding/kites/kloud/kloudctl/command"

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
		"ping":    command.NewPing(),
		"build":   command.NewBuild(),
		"event":   command.NewEvent(),
		"info":    command.NewInfo(),
		"start":   command.NewStart(),
		"stop":    command.NewStop(),
		"destroy": command.NewDestroy(),
		"restart": command.NewRestart(),
		"resize":  command.NewResize(),
		"reinit":  command.NewReinit(),
	}

	_, err := c.Run()
	if err != nil {
		command.DefaultUi.Error(err.Error())
	}
}
