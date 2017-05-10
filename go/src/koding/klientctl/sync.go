package main

import (
	"fmt"
	"os"
	"time"

	"koding/klientctl/endpoint/machine"

	"github.com/codegangsta/cli"
	"github.com/koding/logging"
)

func Sync(c *cli.Context, log logging.Logger, _ string) (int, error) {
	ident := c.Args().Get(0)

	if ident == "" {
		var err error
		if ident, err = os.Getwd(); err != nil {
			return 1, err
		}
	}

	opts := &machine.WaitIdleOptions{
		Identifier: ident,
		Path:       ident,
		Timeout:    c.Duration("timeout"),
	}

	if err := machine.WaitIdle(opts); err != nil {
		return 1, err
	}

	return 0, nil
}

func waitForMount(path string) (err error) {
	const timeout = 1 * time.Minute

	done := make(chan error)

	go func() {
		opts := &machine.WaitIdleOptions{
			Path:    path,
			Timeout: timeout,
		}

		done <- machine.WaitIdle(opts)
	}()

	notice := time.After(1 * time.Second)

	select {
	case err = <-done:
	case <-notice:
		fmt.Fprintf(os.Stderr, "Waiting for mount... ")

		if err = <-done; err == nil {
			fmt.Fprintln(os.Stderr, "ok")
		} else {
			fmt.Fprintln(os.Stderr, "error")
		}
	}

	return err
}
