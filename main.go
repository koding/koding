package main

import (
	"fmt"
	"os"

	"github.com/mitchellh/cli"
)

func main() {
	c := cli.NewCLI(Name, Version)
	c.Args = os.Args[1:]

	c.Commands = map[string]cli.CommandFactory{
		"install":   InstallCommandFactory,
		"start":     StartCommandFactory,
		"stop":      StopCommandFactory,
		"update":    UpdateCommandFactory,
		"uninstall": UninstallCommandFactory,
		"list":      CheckUpdateFirstFactory(ListCommandFactory),
		"mount":     CheckUpdateFirstFactory(MountCommandFactory),
		"unmount":   CheckUpdateFirstFactory(UnmountCommandFactory),
		"ssh":       CheckUpdateFirstFactory(SSHCommandFactory),
		"mounts":    CheckUpdateFirstFactory(MountsCommandFactory),
	}

	i, err := c.Run()
	if err != nil {
		fmt.Println(err)
	}

	os.Exit(i)
}
