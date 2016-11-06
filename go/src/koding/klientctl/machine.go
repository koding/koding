package main

import (
	"fmt"

	"koding/klientctl/machine"

	"github.com/codegangsta/cli"
	"github.com/koding/logging"
)

func MachineListCommand(c *cli.Context, log logging.Logger, _ string) (int, error) {
	opts := &machine.ListOptions{
		Log: log.New("machine:list"),
	}

	ms, err := machine.List(opts)
	if err != nil {
		return 1, err
	}

	fmt.Printf("\nMachines %# v\n\n", ms)
	return 0, nil
}
