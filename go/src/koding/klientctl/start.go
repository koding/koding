package main

import (
	"fmt"
	"koding/klientctl/config"
	"time"

	"github.com/codegangsta/cli"
	"github.com/koding/logging"
)

// StartCommand starts local klient. Requires sudo.
func StartCommand(c *cli.Context, log logging.Logger, _ string) int {
	if len(c.Args()) != 0 {
		cli.ShowCommandHelp(c, "start")
		return 1
	}

	s, err := newService()
	if err != nil {
		log.Error("Error creating Service. err:%s", err)
		fmt.Println(GenericInternalNewCodeError)
		return 1
	}

	if err := s.Start(); err != nil {
		log.Error("Error starting Service. err:%s", err)
		fmt.Println(FailedStartKlient)
		return 1
	}

	fmt.Println("Waiting until started...")

	err = WaitUntilStarted(config.KlientAddress, 15, 1*time.Second)
	if err != nil {
		log.Error(
			"Timed out while waiting for Klient to start. attempts:%d, err:%s",
			15, err,
		)
		fmt.Println(FailedStartKlient)
		return 1
	}

	fmt.Printf("Successfully started %s\n", config.KlientName)
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
