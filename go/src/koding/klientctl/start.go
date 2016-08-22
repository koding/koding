package main

import (
	"fmt"
	"koding/klientctl/config"
	"time"

	"github.com/codegangsta/cli"
	"github.com/koding/logging"
	"github.com/koding/service"
)

// StartCommand starts local klient. Requires sudo.
func StartCommand(c *cli.Context, log logging.Logger, _ string) int {
	if len(c.Args()) != 0 {
		cli.ShowCommandHelp(c, "start")
		return 1
	}

	log = log.New("cmd:start")

	s, err := newService(nil)
	if err != nil {
		log.Error("Error creating Service. err:%s", err)
		fmt.Println(GenericInternalNewCodeError)
		return 1
	}

	// No UX message needed, startKlient will do that itself.
	if err := startKlient(log, s); err != nil {
		log.Error("failed to start klient: %s", err)
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
	for i := 0; i < attempts; i++ {
		time.Sleep(pauseIntv)

		if err = defaultHealthChecker.CheckLocal(); err == nil {
			break
		}
	}
	return err
}

func startKlient(log logging.Logger, s service.Service) error {
	// For debug purposes, run a health check before we even attempt to start. This
	// will help give us a sense of what this machine's health check was before
	// klient tried to start.
	if res, ok := defaultHealthChecker.CheckAllExceptRunning(); !ok {
		log.Warning("before attempting to start klient health check returned not-okay. reason: %s", res)
	}

	if err := s.Start(); err != nil {
		log.Error("Error starting Service. err:%s", err)
		fmt.Println(FailedStartKlient)
		return err
	}

	fmt.Println("Starting...")

	err := WaitUntilStarted(config.KlientAddress, CommandAttempts, CommandWaitTime)
	if err != nil {
		log.Error(
			"Timed out while waiting for Klient to start. attempts:%d, err:%s",
			CommandAttempts, err,
		)

		if s, ok := defaultHealthChecker.CheckAllExceptRunning(); !ok {
			fmt.Printf(`Failed to start %s in time.

A health check found the following issue:
%s
`, config.KlientName, s)
		} else {
			fmt.Println(FailedStartKlient)
		}

		return err
	}

	return nil
}
