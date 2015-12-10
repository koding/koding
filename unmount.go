package main

import (
	"fmt"
	"strings"

	"github.com/codegangsta/cli"
	"github.com/koding/kite"
)

// UnmountCommand unmounts a previously mounted folder by machine name.
func UnmountCommand(c *cli.Context) int {
	if len(c.Args()) != 1 {
		cli.ShowCommandHelp(c, "unmount")
		return 1
	}

	var name = c.Args().First()

	k, err := CreateKlientClient(NewKlientOptions())
	if err != nil {
		fmt.Println(defaultHealthChecker.CheckAllFailureOrMessagef(
			"Error connecting to remote machine: '%s'", err,
		))
		return 1
	}

	if err := k.Dial(); err != nil {
		fmt.Println(defaultHealthChecker.CheckAllFailureOrMessagef(
			"Error connecting to remote machine: '%s'", err,
		))
		return 1
	}

	infos, err := getListOfMachines(k)
	if err != nil {
		fmt.Print(err)
		return 1
	}

	// remove lock file
	for _, info := range infos {
		if strings.HasPrefix(info.VMName, name) && len(info.MountedPaths) > 0 {
			name = info.VMName
			if err := Unlock(info.MountedPaths[0]); err != nil {
				fmt.Printf("Warning: unlocking failed: %s", err)
			}
		}
	}

	// unmount using mount name
	if err := unmount(k, name, ""); err != nil {
		fmt.Printf(defaultHealthChecker.CheckAllFailureOrMessagef(
			"Error unmounting '%s': '%s'\n", name, err,
		))
		return 1
	}

	fmt.Println("Unmount success.")

	return 0
}

func unmount(kite *kite.Client, name, path string) error {
	if err := Unlock(path); err != nil {
		fmt.Printf("Warning: unlocking failed due to %s.", err)
	}

	req := struct{ Name, LocalPath string }{Name: name, LocalPath: path}

	// currently there's no return response to care about
	_, err := kite.Tell("remote.unmountFolder", req)
	return err
}
