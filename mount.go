package main

import (
	"fmt"
	"log"

	"github.com/koding/kite"
	"github.com/mitchellh/cli"
)

func MountCommandFactory(k *kite.Client) cli.CommandFactory {
	return func() (cli.Command, error) {
		return &MountCommand{
			k: k,
		}, nil
	}
}

type MountCommand struct {
	k *kite.Client
}

func (c *MountCommand) Run(args []string) int {
	// All of the arguments are required currently, so error if anything
	// is missing.
	if len(args) != 3 {
		fmt.Printf(c.Help())
		return 1
	}

	err := c.k.Dial()
	if err != nil {
		log.Fatal(err)
		return 1
	}

	mountRequest := struct {
		Ip         string `json:"ip"`
		LocalPath  string `json:"localPath"`
		RemotePath string `json:"remotePath"`
	}{
		Ip:         args[0],
		RemotePath: args[1],
		LocalPath:  args[2],
	}

	// Don't care about the response currently, since there is none.
	_, err = c.k.Tell("remote.mountFolder", mountRequest)
	if err != nil {
		log.Fatal(err)
		return 1
	}

	return 0
}

func (*MountCommand) Help() string {
	helpText := `
Usage: %s mount <machine ip> <remote folder> <local folder>

    Mount a remote folder from the given remote machine, to the specified
    local folder.
`
	return fmt.Sprintf(helpText, Name)
}

func (*MountCommand) Synopsis() string {
	return fmt.Sprintf("Mount a remote folder to a local folder")
}
