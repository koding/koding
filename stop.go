package main

import (
	"fmt"

	"github.com/mitchellh/cli"
)

func StopCommandFactory() (cli.Command, error) {
	return &StopCommand{}, nil
}

type StopCommand struct{}

func (c *StopCommand) Run(_ []string) int {
	s, err := newService()
	if err != nil {
		fmt.Println("Error stopping service: '%s'\n", err)
		return 1
	}

	if err := s.Stop(); err != nil {
		fmt.Println("Error stopping service: '%s'\n", err)
		return 1
	}

	fmt.Printf("Successfully stopped %s\n", KlientName)

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
