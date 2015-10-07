package main

import (
	"fmt"
	"path/filepath"
	"strings"

	"github.com/codegangsta/cli"
)

// MountCommand mounts a folder on remote machine to local folder by machine
// name.
func MountCommand(c *cli.Context) int {
	if len(c.Args()) < 2 {
		cli.ShowCommandHelp(c, "mount")
		return 1
	}

	var (
		name       = c.Args()[0]
		localPath  = c.Args()[1]
		remotePath = c.String("remotepath") // note the lowercase of all chars
	)

	// allow scp like declaration, ie `<machine name>:/path/to/remote`
	if strings.Contains(name, ":") {
		names := strings.Split(name, ":")
		name, remotePath = names[0], names[1]
	}

	// send absolute local path to klient unless local path is empty
	if strings.TrimSpace(localPath) != "" {
		absoluteLocalPath, err := filepath.Abs(localPath)
		if err == nil {
			localPath = absoluteLocalPath
		}
	}

	mountRequest := struct {
		Name       string `json:"name"`
		LocalPath  string `json:"localPath"`
		RemotePath string `json:"remotePath"`
	}{
		Name:      name,
		LocalPath: localPath,
	}

	// RemotePath is optional
	if remotePath != "" {
		mountRequest.RemotePath = remotePath
	}

	k, err := CreateKlientClient(NewKlientOptions())
	if err != nil {
		fmt.Printf("Error connecting to remove machine: '%s'\n", err)
		return 1
	}

	if err := k.Dial(); err != nil {
		fmt.Printf("Error connecting to remove machine: '%s'\n", err)
		return 1
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

	fmt.Println("\nSuccessfully mounted:", localPath)

	return 0
}
