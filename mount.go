package main

import (
	"fmt"
	"log"

	"github.com/mitchellh/cli"
)

func MountCommandFactory() (cli.Command, error) {
	return &MountCommand{}, nil
}

type MountCommand struct{}

func (c *MountCommand) Run(args []string) int {
	// All of the arguments are required currently, so error if anything
	// is missing.
	if len(args) != 3 {
		fmt.Printf(c.Help())
		return 1
	}

	k, err := CreateKlientClient(NewKlientOptions())
	if err != nil {
		log.Fatal(err)
	}

	if err := k.Dial(); err != nil {
		log.Fatal(err)
	}

	mountRequest := struct {
		Name       string `json:"name"`
		LocalPath  string `json:"localPath"`
		RemotePath string `json:"remotePath"`
	}{
		Name:       args[0],
		RemotePath: args[1],
		LocalPath:  args[2],
	}

	// Don't care about the response currently, since there is none.
	if _, err := k.Tell("remote.mountFolder", mountRequest); err != nil {
		return 1
	}

	return 0
}

func (*MountCommand) Help() string {
	helpText := `
Usage: %s mount <machine name> <remote folder> <local folder>

    Mount a remote folder from the given remote machine, to the specified
    local folder.
`
	return fmt.Sprintf(helpText, Name)
}

func (*MountCommand) Synopsis() string {
	return fmt.Sprintf("Mount a remote folder to a local folder")
}
