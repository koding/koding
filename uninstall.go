package main

import (
	"fmt"
	"log"

	"github.com/koding/kite"
	"github.com/mitchellh/cli"
)

func UninstallCommandFactory(k *kite.Client) cli.CommandFactory {
	return func() (cli.Command, error) {
		return &UninstallCommand{
			k: k,
		}, nil
	}
}

type UninstallCommand struct {
	k *kite.Client
}

func (c *UninstallCommand) Run(_ []string) int {
	s, err := newService()
	if err != nil {
		log.Fatal(err)
	}

	err = s.Uninstall()
	if err != nil {
		log.Fatal(err)
	}

	fmt.Println("Success")
	return 0
}

func (*UninstallCommand) Help() string {
	helpText := `
Usage: %s list

	Uninstall the %s.
`
	return fmt.Sprintf(helpText, Name, KlientName)
}

func (*UninstallCommand) Synopsis() string {
	return fmt.Sprintf("Uninstall the %s", KlientName)
}
