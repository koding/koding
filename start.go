package main

import (
	"fmt"
	"log"

	"github.com/koding/kite"
	"github.com/mitchellh/cli"
)

func StartCommandFactory(k *kite.Client) cli.CommandFactory {
	return func() (cli.Command, error) {
		return &StartCommand{
			k: k,
		}, nil
	}
}

type StartCommand struct {
	k *kite.Client
}

func (c *StartCommand) Run(_ []string) int {
	s, err := newService()
	if err != nil {
		log.Fatal(err)
	}

	err = s.Start()
	if err != nil {
		log.Fatal(err)
	}

	fmt.Println("Success")
	return 0
}

func (*StartCommand) Help() string {
	helpText := `
Usage: %s stop

	Start the %s.
`
	return fmt.Sprintf(helpText, Name, KlientName)
}

func (*StartCommand) Synopsis() string {
	return fmt.Sprintf("Start the %s", KlientName)
}
