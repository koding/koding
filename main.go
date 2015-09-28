package main

import (
	"fmt"
	"log"
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
		"uninstall": UninstallCommandFactory,
		"list":      CheckUpdateFirstFactory(ListCommandFactory),
		"mount":     CheckUpdateFirstFactory(MountCommandFactory),
		"unmount":   CheckUpdateFirstFactory(UnmountCommandFactory),
		"mounts":    CheckUpdateFirstFactory(MountsCommandFactory),
	}

	i, err := c.Run()
	if err != nil {
		log.Fatal(err)
	}

	os.Exit(i)
}

type CheckUpdateFirst struct {
	RealCli cli.Command
}

func CheckUpdateFirstFactory(realFactory func() (cli.Command, error)) func() (cli.Command, error) {
	realCli, err := realFactory()
	if err != nil {
		panic(err)
	}

	return func() (cli.Command, error) { return &CheckUpdateFirst{RealCli: realCli}, nil }
}

func (c *CheckUpdateFirst) Run(args []string) int {
	u := NewCheckUpdate()
	if y, err := u.IsUpdateAvailable(); y && err == nil {
		fmt.Println("A newer version of kd is available. Please do `sudo kd update`.\n")
	}

	return c.RealCli.Run(args)
}

func (c *CheckUpdateFirst) Help() string {
	return c.RealCli.Help()
}

func (c *CheckUpdateFirst) Synopsis() string {
	return c.RealCli.Synopsis()
}
