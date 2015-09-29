package main

import (
	"fmt"
	"log"

	"github.com/mitchellh/cli"
)

func StopCommandFactory() (cli.Command, error) {
	return &StopCommand{}, nil
}

type StopCommand struct{}

func (c *StopCommand) Run(_ []string) int {
	s, err := newService()
	if err != nil {
		log.Fatal(err)
	}

	err = s.Stop()
	if err != nil {
		log.Fatal(err)
	}

	fmt.Printf("Successfully stopped the %s\n", KlientName)
	return 0
}

func (*StopCommand) Help() string {
	helpText := `
Usage: sudo %s stop

	Stop the %s. sudo is required.
`
	return fmt.Sprintf(helpText, Name, KlientName)
}

func (*StopCommand) Synopsis() string {
	return fmt.Sprintf("Stop the %s. sudo required.", KlientName)
}
