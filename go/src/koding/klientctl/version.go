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
	if c, err := kiteconfig.NewFromKiteKey(config.KiteKeyPath); err == nil && c.Id != "" {
		fmt.Printf("kd version %s (Kite Query ID: %s, Environment: %s)\n", config.Version, c.Id, config.Environment)
		return 0
	}

	fmt.Printf("kd version %s (Environment: %s)\n", config.Version, config.Environment)
	return 0
}
