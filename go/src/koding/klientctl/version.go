package main

import (
	"fmt"

	"koding/klientctl/config"

	"github.com/koding/logging"
	cli "gopkg.in/urfave/cli.v1"
)

type version struct {
	Installed   int    `json:"installed"`
	Latest      int    `json:"latest"`
	Environment string `json:"environment"`
	KiteID      string `json:"kiteID"`
}

// VersionCommand displays version information like Environment or Kite Query ID.
func VersionCommand(c *cli.Context, log logging.Logger, _ string) int {
	v := &version{
		Installed:   config.VersionNum(),
		Environment: config.Environment,
		KiteID:      config.Konfig.KiteConfig().Id,
	}

	v.Latest, _ = latestVersion(config.Konfig.Endpoints.KDLatest.Public.String())

	if c.Bool("json") {
		printJSON(v)
	} else {
		fmt.Printf("Installed Version: %s\n", getReadableVersion(v.Installed))
		fmt.Printf("Latest Version: %s\n", getReadableVersion(v.Latest))
		fmt.Println("Environment:", v.Environment)
		fmt.Println("Kite Query ID:", v.KiteID)
	}

	return 0
}

func getReadableVersion(version int) string {
	if version == 0 {
		return "-"
	}
	return fmt.Sprintf("0.1.%d", version)
}
