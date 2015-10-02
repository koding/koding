package main

import (
	"fmt"
	"path/filepath"
	"strings"

	"github.com/codegangsta/cli"
)

func MountCommand(c *cli.Context) int {
	if len(c.Args()) < 2 {
		cli.ShowCommandHelp(c, "mount")
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

	var localPath = c.Args()[1]

	// send absolute path to klient unless local path is empty
	if strings.TrimSpace(c.Args()[1]) != "" {
		absoluteLocalPath, err := filepath.Abs(c.Args()[1])
		if err == nil {
			localPath = absoluteLocalPath
		}
	}

	mountRequest := struct {
		Name       string `json:"name"`
		LocalPath  string `json:"localPath"`
		RemotePath string `json:"remotePath"`
	}{
		Name:      c.Args()[0],
		LocalPath: localPath,
	}

	// `RemotePath` is optional; klient defaults to user VM's home directory
	if len(c.Args()) > 2 {
		mountRequest.RemotePath = c.Args()[2]
	}

	resp, err := k.Tell("remote.mountFolder", mountRequest)
	if err != nil {
		fmt.Printf("Error mounting folder: '%s'\n", err)
		return 1
	}

	// response can be nil even when there's no err
	if resp != nil {
		var warning string
		if err := resp.Unmarshal(&warning); err != nil {
			return 0
		}

		if len(warning) > 0 {
			fmt.Printf("Warning: %s\n", warning)
		}
	}

	fmt.Println("Successfully mounted:", localPath)

	return 0
}
