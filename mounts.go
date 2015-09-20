package main

import (
	"fmt"

	"github.com/koding/kite"
	"github.com/mitchellh/cli"
)

func MountsCommandFactory(k *kite.Client) cli.CommandFactory {
	return func() (cli.Command, error) {
		return &MountsCommand{
			k: k,
		}, nil
	}
}

type MountsCommand struct {
	k *kite.Client
}

func (c *MountsCommand) Run(_ []string) int {
	fmt.Println("Not implemented")
	return 1
}

func (*MountsCommand) Help() string {
	helpText := `
Usage: %s mounts

	List the mounted folders on this machine.
`
	return fmt.Sprintf(helpText, Name, KlientName)
}

func (*MountsCommand) Synopsis() string {
	return fmt.Sprintf("List mounted folders on this machine")
}
