package main

import (
	"fmt"

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
		fmt.Printf("Error connecting to remote machine: '%s'\n", err)
		return 1
	}

	if err := k.Dial(); err != nil {
		fmt.Printf("Error connecting to remote machine: '%s'\n", err)
		return 1
	}

	if err := unmount(k, name, ""); err != nil {
		fmt.Printf("Error unmounting '%s': '%s'\n", name, err)
		return 1
	}

	fmt.Println("Successfully unmounted:", name)

	return 0
}

func unmount(kite *kite.Client, name, path string) error {
	req := struct{ Name, LocalPath string }{Name: name, LocalPath: path}

	// currently there's no return response to care about
	_, err := kite.Tell("remote.unmountFolder", req)
	return err
}
