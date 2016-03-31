package main

import (
	"fmt"
	"koding/klientctl/klient"
	"koding/klientctl/remount"

	"github.com/codegangsta/cli"
	"github.com/koding/logging"
)

func RemountCommand(c *cli.Context, _ logging.Logger, _ string) int {
	if len(c.Args()) != 1 {
		cli.ShowCommandHelp(c, "remount")
		return 1
	}

	cmd := remount.RemountCommand{
		MountName:     c.Args()[0],
		KlientOptions: klient.NewKlientOptions(),
	}

	if err := cmd.Run(); err != nil {
		fmt.Printf("Error: %s", err)
		return 1
	}

	return 0
}
