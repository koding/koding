package main

import (
	"fmt"

	"github.com/codegangsta/cli"
)

func StartCommand(c *cli.Context) int {
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
