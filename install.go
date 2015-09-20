package main

import (
	"fmt"

	"github.com/koding/kite"
	"github.com/mitchellh/cli"
)

func InstallCommandFactory(k *kite.Client) cli.CommandFactory {
	return func() (cli.Command, error) {
		return &InstallCommand{
			k: k,
		}, nil
	}
}

type InstallCommand struct {
	k *kite.Client
}

func (c *InstallCommand) Run(_ []string) int {
	fmt.Println("Not implemented")
	return 1
}

func (*InstallCommand) Help() string {
	helpText := `
Usage: %s list

	Install the %s.
`
	return fmt.Sprintf(helpText, Name, KlientName)
}

func (*InstallCommand) Synopsis() string {
	return fmt.Sprintf("Install the %s", KlientName)
}
