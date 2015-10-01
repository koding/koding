package main

import (
	"fmt"

	"github.com/codegangsta/cli"
)

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

//func (*StopCommand) Help() string {
//	helpText := `
//Usage: sudo %s stop
//
//	Stop the %s. sudo is required.
//`
//	return fmt.Sprintf(helpText, Name, KlientName)
//}
//
//func (*StopCommand) Synopsis() string {
//	return fmt.Sprintf("Stop the %s. sudo required.", KlientName)
//}
