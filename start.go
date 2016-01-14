package main

import (
	"fmt"
	"time"

	"github.com/codegangsta/cli"
)

// StartCommand starts local klient. Requires sudo.
func StartCommand(c *cli.Context) int {
	if len(c.Args()) != 0 {
		cli.ShowCommandHelp(c, "start")
		return 1
	}

	s, err := newService()
	if err != nil {
		log.Errorf("Error creating Service. err:%s", err)
		fmt.Println(GenericInternalNewCodeError)
		return 1
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

	fmt.Printf("Successfully started %s\n", KlientName)
	return 0
}

// WaitUntilStarted uses the default health checker to wait until the local client is
// running healthily.
//
// TODO: Change address to a HealthChecker.
func WaitUntilStarted(address string, attempts int, pauseIntv time.Duration) error {
	var err error
	// Try multiple times to connect to Klient, and return the final error
	// if needed.
	for i := 0; i < 5; i++ {
		time.Sleep(pauseIntv)

		if err = defaultHealthChecker.CheckLocal(); err == nil {
			break
		}
	}
	return err
}
