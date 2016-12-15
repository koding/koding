package main

import (
	"errors"
	"fmt"
	"koding/klientctl/config"
	"time"

	"github.com/codegangsta/cli"
	"github.com/koding/logging"
)

// StopCommand stop local klient. Requires sudo.
func StopCommand(c *cli.Context, log logging.Logger, _ string) int {
	if len(c.Args()) != 0 {
		cli.ShowCommandHelp(c, "stop")
		return 1
	}

	s, err := newService(nil)
	if err != nil {
		log.Error("Error creating Service. err:%s", err)
		fmt.Println(GenericInternalError)
		return 1
	}

	if err := s.Stop(); err != nil {
		log.Error("Error stopping Service. err:%s", err)
		fmt.Println(FailedStopKlient)
		return 1
	}

	err = WaitUntilStopped(config.Konfig.Endpoints.Klient.Private.String(), CommandAttempts, CommandWaitTime)
	if err != nil {
		log.Error(
			"Timed out while waiting for Klient to start. attempts:%d, err:%s",
			5, err,
		)
		fmt.Println(FailedStopKlient)
		return 1
	}

	fmt.Printf("Successfully stopped %s\n", config.KlientName)
	return 0
}

// WaitUntilStopped repeatedly checks to see if Klient is running, and waiting until
// it is no longer running.
func WaitUntilStopped(address string, attempts int, pauseIntv time.Duration) error {
	// Wait for klient
	for i := 0; i < 5; i++ {
		time.Sleep(pauseIntv)

		if !IsKlientRunning(address) {
			return nil
		}
	}

	return errors.New("Klient failed to stop in the expected time")
}
