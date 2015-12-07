package main

import (
	"errors"
	"fmt"
	"time"

	"github.com/codegangsta/cli"
)

// StopCommand stop local klient. Requires sudo.
func StopCommand(c *cli.Context) int {
	s, err := newService()
	if err != nil {
		fmt.Printf("Error stopping service: '%s'\n", err)
		return 1
	}

	if err := s.Stop(); err != nil {
		fmt.Printf("Error stopping service: '%s'\n", err)
		return 1
	}

	if err := WaitUntilStopped(KlientAddress, 5, 1*time.Second); err != nil {
		fmt.Printf("Timed out waiting for the %s to stop\n", KlientName)
		return 1
	}

	fmt.Printf("Successfully stopped %s\n", KlientName)

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
