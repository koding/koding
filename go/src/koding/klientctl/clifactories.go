// ctifactories implements abstractions ontop of the CLI commands, interfacting the
// CLI library of choice with the klientctl Commands created.
//
// TODO: Move this to it's own package, once the rest of the klientctl lib is
// package-able.
package main

import (
	"fmt"
	"koding/klientctl/util/mountcli"
	"os"

	"github.com/codegangsta/cli"
	"github.com/koding/logging"
)

// MountCommandFactory creates a mount.Command instance and runs it with
// Stdin and Out.
func UnmountCommandFactory(c *cli.Context, log logging.Logger, cmdName string) int {
	log = log.New(fmt.Sprintf("command:%s", cmdName))

	// Full our unmount options from the CLI. Any empty options are okay, as
	// the command struct is responsible for verifying valid opts.
	opts := UnmountOptions{
		MountName: c.Args().First(),
	}

	cmd := &UnmountCommand{
		Options:       opts,
		Stdout:        os.Stdout,
		Stdin:         os.Stdin,
		Log:           log,
		KlientOptions: NewKlientOptions(),
		helper:        CommandHelper(c, cmdName),
		healthChecker: defaultHealthChecker,
		fileRemover:   os.Remove,
		mountFinder:   mountcli.NewMount(),
	}

	exit, err := cmd.Run()
	if exit != 0 || err != nil {
		// Using the command logger, since it may be using its own prefixes.
		cmd.Log.Error("Command encountered error. exit:%d, err:%s", exit, err)
	}

	return exit
}
