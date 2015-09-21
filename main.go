package main

import (
	"log"
	"os"

	"github.com/mitchellh/cli"
)

func main() {
	c := cli.NewCLI(Name, Version)
	c.Args = os.Args[1:]

	c.Commands = map[string]cli.CommandFactory{
		"install":   InstallCommandFactory,
		"list":      ListCommandFactory,
		"mount":     MountCommandFactory,
		"unmount":   UnmountCommandFactory,
		"mounts":    MountsCommandFactory,
		"start":     StartCommandFactory,
		"stop":      StopCommandFactory,
		"uninstall": UninstallCommandFactory,
	}

	if _, err := c.Run(); err != nil {
		log.Fatal(err)
	}
}
