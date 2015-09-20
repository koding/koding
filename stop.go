package main

import (
	"fmt"
	"log"

	"github.com/koding/kite"
	"github.com/mitchellh/cli"
)

func StopCommandFactory(k *kite.Client) cli.CommandFactory {
	return func() (cli.Command, error) {
		return &StopCommand{
			k: k,
		}, nil
	}
}

type StopCommand struct {
	k *kite.Client
}

func (c *StopCommand) Run(_ []string) int {
	s, err := newService()
	if err != nil {
		log.Fatal(err)
	}

	err = s.Stop()
	if err != nil {
		log.Fatal(err)
	}

	fmt.Println("Success")
	return 0
}

func (*StopCommand) Help() string {
	helpText := `
Usage: %s stop

	Stop the %s.
`
	return fmt.Sprintf(helpText, Name, KlientName)
}

func (*StopCommand) Synopsis() string {
	return fmt.Sprintf("Stop the %s", KlientName)
}
