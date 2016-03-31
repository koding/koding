package main

import (
	"fmt"

	"github.com/koding/logging"

	"koding/klientctl/metrics"
	"koding/klientctl/ssh"

	"github.com/codegangsta/cli"
)

// SSHCommandFactory is the factory method for SSHCommand.
func SSHCommandFactory(c *cli.Context, log logging.Logger, _ string) int {
	if len(c.Args()) != 1 {
		cli.ShowCommandHelp(c, "ssh")
		return 1
	}

	cmd, err := ssh.NewSSHCommand(true)

	// TODO: Refactor SSHCommand instance to require no initialization,
	// and thus avoid needing to log an error in a weird place.
	if err != nil {
		log.Error("Error initializing ssh: %s", err)
		fmt.Println(GenericInternalError)

		return 1
	}

	mountName := c.Args()[0]

	// track metrics
	go func() {
		metrics.TrackSSH(mountName)
	}()

	err = cmd.Run(mountName)
	switch err {
	case nil:
		return 0
	case ssh.ErrManagedMachineNotSupported:
		fmt.Println(CannotSSHManaged)
	case ssh.ErrFailedToGetSSHKey:
		fmt.Println(FailedGetSSHKey)
	case ssh.ErrMachineNotValidYet:
		fmt.Println(defaultHealthChecker.CheckAllFailureOrMessagef(MachineNotValidYet))
	case ssh.ErrDialingFailed:
		fmt.Println(defaultHealthChecker.CheckAllFailureOrMessagef(FailedDialingRemote))
	}

	// track metrics
	if err != nil {
		metrics.TrackSSHFailed(mountName, err.Error())
	}

	log.Error("SSHCommand.Run returned err:%s", err)

	return 1
}
