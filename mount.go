package main

import (
	"fmt"
	"path/filepath"
	"strings"

	"github.com/codegangsta/cli"
)

func MountCommand(c *cli.Context) int {
	//if len(args) < 2 {
	//	fmt.Println(c.Help())
	//	return 1
	//}

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

	// use absolute path unless empty
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

	if len(c.Args()) > 2 {
		mountRequest.RemotePath = c.Args()[2]
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
