package main

import (
	"fmt"

	"github.com/codegangsta/cli"
)

// StopCommand stop local klient. Requires sudo.
func StopCommand(c *cli.Context) int {
	s, err := newService()
	if err != nil {
		fmt.Printf("Error stopping service: '%s'\n", err)
		return 1
	}

	if err := s.Stop(); err != nil {
		fmt.Printf("Error stopping service: '%s'\n", err)
		return 1
	}

	fmt.Printf("Successfully stopped %s\n", KlientName)

	return 0
}
