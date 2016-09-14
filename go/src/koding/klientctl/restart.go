package main

import (
	"fmt"
	"koding/klientctl/config"

	"github.com/codegangsta/cli"
	"github.com/koding/logging"
)

// RestartCommand stops and starts klient. If Klient is not running to begin
// with, it *just* starts klient.
func RestartCommand(c *cli.Context, log logging.Logger, _ string) int {
	if len(c.Args()) != 0 {
		cli.ShowCommandHelp(c, "restart")
		return 1
	}

	log = log.New("cmd:restart")

	s, err := newService(nil)
	if err != nil {
		log.Error("Error creating Service. err:%s", err)
		fmt.Println(GenericInternalNewCodeError)
		return 1
	}

	fmt.Printf("Restarting the %s, this may take a moment...\n", config.KlientName)

	klientWasRunning := IsKlientRunning(config.KlientAddress)

	if klientWasRunning {
		// If klient is running, stop it, and tell the user if we fail
		if err := s.Stop(); err != nil {
			log.Error("Error stopping Service. err:%s", err)
			fmt.Println(FailedStopKlient)
			return 1
		}
	} else {
		// If klient appears to not be running, try to stop it anyway. However,
		// because it may not actually be running, don't inform the user if we fail here.
		s.Stop()
	}

	err = WaitUntilStopped(config.KlientAddress, CommandAttempts, CommandWaitTime)
	if err != nil {
		log.Error(
			"Timed out while waiting for Klient to start. attempts:%d, err:%s",
			5, err,
		)
		fmt.Println(FailedStopKlient)
		return 1
	}

	if klientWasRunning {
		fmt.Println("Stopped successfully.")
	}

	// No UX message needed, startKlient will do that itself.
	if err := startKlient(log, s); err != nil {
		log.Error("failed to start klient: %s", err)
		return 1
	}

	fmt.Printf("Successfully restarted %s\n", config.KlientName)
	return 0
}
