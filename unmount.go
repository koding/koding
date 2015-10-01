package main

import (
	"fmt"

	"github.com/codegangsta/cli"
)

func UnmountCommand(c *cli.Context) int {
	//// All of the arguments are required currently, so error if anything
	//// is missing.
	//if len(args) != 1 {
	//	fmt.Printf(c.Help())
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

	mountRequest := struct {
		Name string `json:"name"`
	}{Name: c.Args().First()}

	// Don't care about the response currently, since there is none.
	if _, err := k.Tell("remote.unmountFolder", mountRequest); err != nil {
		fmt.Printf("Error unmounting %s: '%s'\n", c.Args().First(), err)
		return 1
	}

	fmt.Println("Successfully unmounted:", c.Args().First())
	return 0
}
