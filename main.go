package main

import (
	"log"
	"os"

	"github.com/mitchellh/cli"
)

func main() {
	c := cli.NewCLI(Name, Version)
	c.Args = os.Args[1:]

	k, err := CreateKlientClient(NewKlientOptions())
	if err != nil {
		log.Fatal(err)
	}

	c.Commands = map[string]cli.CommandFactory{
		"install":   InstallCommandFactory(k),
		"list":      ListCommandFactory(k),
		"mount":     MountCommandFactory(k),
		"unmount":   UnmountCommandFactory(k),
		"mounts":    MountsCommandFactory(k),
		"start":     StartCommandFactory(k),
		"stop":      StopCommandFactory(k),
		"uninstall": UninstallCommandFactory(k),
	}

	if _, err = c.Run(); err != nil {
		log.Fatal(err)
	}
}
