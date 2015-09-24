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
	if len(args) < 2 {
		log.Fatal(c.Help())
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
		Name:      args[0],
		LocalPath: args[1],
	}

	if len(args) > 2 {
		mountRequest.RemotePath = args[2]
	}

	// Don't care about the response currently, since there is none.
	if _, err := k.Tell("remote.mountFolder", mountRequest); err != nil {
		log.Fatal(err)
	}

	return 0
}

func (*MountCommand) Help() string {
	helpText := `
Usage: %s mount <machine name> </fullpath/to/local/folder> </fullpath/to/remote/folder>

    Mount a remote folder from the given remote machine, to the specified
    local folder. Please use full paths.
`
	return fmt.Sprintf(helpText, Name)
}

func (*MountCommand) Synopsis() string {
	return fmt.Sprintf("Mount a remote folder to a local folder")
}
