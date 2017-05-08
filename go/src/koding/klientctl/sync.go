package main

import (
	"os"

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
