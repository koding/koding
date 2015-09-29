package main

import (
	"fmt"
	"log"

	"github.com/mitchellh/cli"
)

func StartCommandFactory() (cli.Command, error) {
	return &StartCommand{}, nil
}

type StartCommand struct{}

func (c *StartCommand) Run(_ []string) int {
	s, err := newService()
	if err != nil {
		log.Fatal(err)
	}

	err = s.Start()
	if err != nil {
		log.Fatal(err)
	}

	fmt.Printf("Successfully started the %s\n", KlientName)
	return 0
}

func (*StartCommand) Help() string {
	helpText := `
Usage: sudo %s start

	Start the %s. sudo is required.
`
	return fmt.Sprintf(helpText, Name, KlientName)
}

func (*StartCommand) Synopsis() string {
	return fmt.Sprintf("Start the %s. sudo required.", KlientName)
}
