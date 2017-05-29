package main

import (
	"fmt"

	"github.com/koding/logging"

	"koding/klientctl/config"
	"koding/klientctl/shortcut"
	"koding/klientctl/ssh"

	cli "gopkg.in/urfave/cli.v1"
)

// SSHCommandFactory is the factory method for SSHCommand.
func SSHCommandFactory(c *cli.Context, log logging.Logger, _ string) int {
	if len(c.Args()) != 1 {
		cli.ShowCommandHelp(c, "ssh")
		return 1
	}

	if c.Bool("debug") {
		log.SetLevel(logging.DEBUG)
	}

	opts := ssh.SSHCommandOpts{
		Debug:          c.Bool("debug") || config.Konfig.Debug,
		RemoteUsername: c.String("username"),
		Ask:            true,
	}
	cmd, err := ssh.NewSSHCommand(log, opts)
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
		return 1
	}

	err = cmd.Run(mountName)
	switch err {
	case nil:
		return 0
	case ssh.ErrMachineNotFound:
		fmt.Println(MachineNotFound)
	case ssh.ErrCannotFindUser:
		fmt.Println(CannotFindSSHUser)
	case ssh.ErrFailedToGetSSHKey:
		fmt.Println(FailedGetSSHKey)
	case ssh.ErrMachineNotValidYet:
		fmt.Println(defaultHealthChecker.CheckAllFailureOrMessagef(MachineNotValidYet))
	case ssh.ErrRemoteDialingFailed:
		fmt.Println(defaultHealthChecker.CheckAllFailureOrMessagef(FailedDialingRemote))
	case shortcut.ErrMachineNotFound:
		fmt.Println(MachineNotFound)
	}

	log.Error("SSHCommand.Run returned err:%s", err)

	return 1
}
