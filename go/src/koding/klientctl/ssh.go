package main

import (
	"fmt"

	"github.com/koding/logging"

	"koding/klientctl/config"
	"koding/klientctl/metrics"
	"koding/klientctl/shortcut"
	"koding/klientctl/ssh"

	"github.com/codegangsta/cli"
)

// SSHCommandFactory is the factory method for SSHCommand.
func SSHCommandFactory(c *cli.Context, log logging.Logger, _ string) int {
	if len(c.Args()) != 1 {
		cli.ShowCommandHelp(c, "ssh")
		return 1
	}

	mountName := c.Args()[0]

	cmd, err := ssh.NewSSHCommand(log, true)
	mountName := c.Args()[0]

	// TODO: Refactor SSHCommand instance to require no initialization,
	// and thus avoid needing to log an error in a weird place.
	if err != nil {
		log.Error("Error initializing ssh: %s", err)
		switch err {
		case ssh.ErrLocalDialingFailed:
			fmt.Println(
				defaultHealthChecker.CheckAllFailureOrMessagef(KlientIsntRunning),
			)
		default:
			fmt.Println(GenericInternalError)
		}

		metrics.TrackSSHFailed(mountName, err.Error(), config.VersionNum())
		return 1
	}

	// track metrics
	go func() {
		metrics.TrackSSH(mountName, config.VersionNum())
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
	case ssh.ErrRemoteDialingFailed:
		fmt.Println(defaultHealthChecker.CheckAllFailureOrMessagef(FailedDialingRemote))
	case shortcut.ErrMachineNotFound:
		fmt.Println(MachineNotFound)
	}

	// track metrics
	if err != nil {
		metrics.TrackSSHFailed(mountName, err.Error(), config.VersionNum())
	}

	log.Error("SSHCommand.Run returned err:%s", err)

	return 1
}
