package main

import (
	"fmt"

	"github.com/mitchellh/cli"
)

func UnmountCommandFactory() (cli.Command, error) {
	return &UnmountCommand{}, nil
}

type UnmountCommand struct{}

func (c *UnmountCommand) Run(args []string) int {
	// All of the arguments are required currently, so error if anything
	// is missing.
	if len(args) != 1 {
		fmt.Printf(c.Help())
		return 1
	}

	k, err := CreateKlientClient(NewKlientOptions())
	if err != nil {
		fmt.Printf("Error connecting to remote VM: '%s'\n", err)
		return 1
	}

	if err := k.Dial(); err != nil {
		fmt.Printf("Error connecting to remote VM: '%s'\n", err)
		return 1
	}

	mountRequest := struct {
		Name string `json:"name"`
	}{Name: args[0]}

	// Don't care about the response currently, since there is none.
	if _, err := k.Tell("remote.unmountFolder", mountRequest); err != nil {
		fmt.Printf("Error unmounting %s: '%s'\n", args[0], err)
		return 1
	}

	fmt.Println("Successfully unmounted:", args[0])

	return 0
}

func (*UnmountCommand) Help() string {
	helpText := `
Usage: %s unmount <machine name>

    Unmount a machine which was previously mounted.
`
	return fmt.Sprintf(helpText, Name)
}

func (*UnmountCommand) Synopsis() string {
	return fmt.Sprintf("Unmount specified machine.")
}
