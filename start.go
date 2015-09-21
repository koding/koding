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
