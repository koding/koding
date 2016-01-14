package main

import (
	"fmt"
	"time"

	"github.com/codegangsta/cli"
)

// RestartCommand stops and starts klient. If Klient is not running to begin
// with, it *just* starts klient.
func RestartCommand(c *cli.Context) int {
	if len(c.Args()) != 0 {
		cli.ShowCommandHelp(c, "restart")
		return 1
	}

	s, err := newService()
	if err != nil {
		log.Errorf("Error creating Service. err:%s", err)
		fmt.Println(GenericInternalNewCodeError)
		return 1
	}

	fmt.Printf("Restarting the %s, this may take a moment...\n", KlientName)

	// Only worry about stopping if klient is actually running.
	if IsKlientRunning(KlientAddress) {
		if err := s.Stop(); err != nil {
			log.Errorf("Error stopping Service. err:%s", err)
			fmt.Println(FailedStopKlient)
			return 1
		}

		if err := WaitUntilStopped(KlientAddress, 5, 1*time.Second); err != nil {
			log.Errorf(
				"Timed out while waiting for Klient to start. attempts:%d, err:%s",
				5, err,
			)
			fmt.Println(FailedStopKlient)
			return 1
		}

		fmt.Println("Stopped successfully.")
	}

	if err := s.Start(); err != nil {
		log.Errorf("Error starting Service. err:%s", err)
		fmt.Println(FailedStartKlient)
		return 1
	}

	fmt.Println("Waiting until started...")
	if err := WaitUntilStarted(KlientAddress, 5, 1*time.Second); err != nil {
		log.Errorf(
			"Timed out while waiting for Klient to start. attempts:%d, err:%s",
			5, err,
		)
		fmt.Println(FailedStartKlient)
		return 1
	}

	fmt.Printf("Successfully restarted %s\n", KlientName)
	return 0
}
