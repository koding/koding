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
		"kontrol":         command.NewKontrol(),
		"vagrant":         command.NewVagrant(),
		"migrate":         command.NewMigrate(),
		"team":            command.NewTeam(),
		"group":           command.NewGroup(),
		"ping":            command.NewPing(),
		"event":           command.NewEvent(),
		"info":            command.NewInfo(),
		"build":           command.NewBuild(),
		"start":           command.NewCmd("start"),
		"stop":            command.NewCmd("stop"),
		"destroy":         command.NewCmd("destroy"),
		"restart":         command.NewCmd("restart"),
		"resize":          command.NewCmd("resize"),
		"reinit":          command.NewCmd("reinit"),
		"create-snapshot": command.NewCmd("createSnapshot"),
		"delete-snapshot": command.NewDeleteSnapshot(),
	}

	_, err := c.Run()
	if err != nil {
		command.DefaultUi.Error(err.Error())
	}
}
