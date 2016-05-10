package main

import (
	"fmt"

	"koding/klientctl/config"

	"github.com/codegangsta/cli"
	kiteconfig "github.com/koding/kite/config"
	"github.com/koding/logging"
)

// VersionCommand displays version information like Environment or Kite Query ID.
func VersionCommand(c *cli.Context, log logging.Logger, _ string) int {
	latest, err := latestVersion(config.S3KlientctlLatest)

	fmt.Println("Installed Version:", config.Version)

	if err == nil && latest != 0 {
		fmt.Println("Latest Version:", latest)
	}

	fmt.Println("Environment:", config.Environment)

	if c, err := kiteconfig.NewFromKiteKey(config.KiteKeyPath); err == nil && c.Id != "" {
		fmt.Println("Kite Query ID:", c.Id)
	}

	return 0
}
