package main

import (
	"fmt"
	"time"

	"github.com/codegangsta/cli"
)

// RestartCommand stops and starts klient. If Klient is not running to begin
// with, it *just* starts klient.
func RestartCommand(c *cli.Context) int {
	s, err := newService()
	if err != nil {
		fmt.Printf("Error restarting %s: '%s'\n", KlientName, err)
		return 1
	}

	fmt.Printf("Restarting the %s, this may take a moment...\n", KlientName)

	// Only worry about stopping if klient is actually running.
	if IsKlientRunning(KlientAddress) {
		if err := s.Stop(); err != nil {
			fmt.Printf("Error stopping service: '%s'\n", err)
			return 1
		}

		if err := WaitUntilStopped(KlientAddress, 5, 1*time.Second); err != nil {
			fmt.Printf("Timed out waiting for the %s to stop\n", KlientName)
			return 1
		}

		fmt.Println("Stopped successfully.")
	}

	if err := s.Start(); err != nil {
		fmt.Printf("Error starting %s: '%s'\n", KlientName, err)
		return 1
	}

	fmt.Println("Waiting until started...")
	if err := WaitUntilStarted(KlientAddress, 5, 1*time.Second); err != nil {
		fmt.Printf("Timed out waiting for the %s to start\n", KlientName)
		return 1
	}

	fmt.Printf("Successfully restarted %s\n", KlientName)
	return 0
}
