package main

import (
	"fmt"

	"koding/klientctl/machine"

	"github.com/codegangsta/cli"
	"github.com/koding/logging"
)

func MachineListCommand(c *cli.Context, log logging.Logger, _ string) int {
	opts := &machine.ListOptions{
		Log: log.NewLogger("machine:list"),
	}

	ms, err := machine.List()
	if err != nil {
		return 1
	}

	fmt.Printf("\nMachines %# v\n\n", ms)
	return 0
}
