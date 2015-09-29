package main

import (
	"fmt"
	"path/filepath"
	"strings"

	"github.com/mitchellh/cli"
)

func MountCommandFactory() (cli.Command, error) {
	return &MountCommand{}, nil
}

type MountCommand struct{}

func (c *MountCommand) Run(args []string) int {
	if len(args) < 2 {
		fmt.Println(c.Help())
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

	var localPath = args[1]

	// use absolute path unless empty
	if strings.TrimSpace(args[1]) != "" {
		absoluteLocalPath, err := filepath.Abs(args[1])
		if err == nil {
			localPath = absoluteLocalPath
		}
	}

	mountRequest := struct {
		Name       string `json:"name"`
		LocalPath  string `json:"localPath"`
		RemotePath string `json:"remotePath"`
	}{
		Name:      args[0],
		LocalPath: localPath,
	}

	if len(args) > 2 {
		mountRequest.RemotePath = args[2]
	}

	resp, err := k.Tell("remote.mountFolder", mountRequest)
	if err != nil {
		fmt.Printf("Error fetching list of mounts from: '%s'\n", KlientName, err)
		return 1
	}

	if resp == nil {
		return 0
	}

	var warning string
	if err := resp.Unmarshal(&warning); err != nil {
		return 0
	}

	if len(warning) > 0 {
		fmt.Printf("Warning: %s\n", warning)
	}

	fmt.Println("Successfully mounted:", localPath)

	return 0
}

func (*MountCommand) Help() string {
	helpText := `
Usage: %s mount <machine name> </path/to/local/folder> </path/to/remote/folder>

    Mount a remote folder from the given remote machine, to the specified
    local folder.
`
	return fmt.Sprintf(helpText, Name)
}

func (*MountCommand) Synopsis() string {
	return fmt.Sprintf("Mount a remote folder to a local folder")
}
