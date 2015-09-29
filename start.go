package main

import (
	"fmt"

	"github.com/mitchellh/cli"
)

func StartCommandFactory() (cli.Command, error) {
	return &StartCommand{}, nil
}

type StartCommand struct{}

func (c *StartCommand) Run(_ []string) int {
	s, err := newService()
	if err != nil {
		fmt.Printf("Error starting %s: '%s'\n", KlientName, err)
		return 1
	}

	if err := s.Start(); err != nil {
		fmt.Printf("Error starting %s: '%s'\n", KlientName, err)
		return 1
	}

	fmt.Printf("Successfully started %s\n", KlientName)

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
