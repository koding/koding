package main

import (
	"fmt"
	"strconv"

	"koding/klientctl/config"

	"github.com/codegangsta/cli"
	"github.com/koding/logging"
)

// VersionCommand displays version information like Environment or Kite Query ID.
func VersionCommand(c *cli.Context, log logging.Logger, _ string) int {
	latest, err := latestVersion(config.Konfig.Endpoints.KDLatest.Public.String())

	fmt.Printf("Installed Version: %s\n", getReadableVersion(config.Version))

	if err == nil && latest != 0 {
		fmt.Printf("Latest Version: %s\n", getReadableVersion(strconv.Itoa(latest)))
	}

	fmt.Println("Environment:", config.Environment)
	fmt.Println("Kite Query ID:", config.Konfig.KiteConfig().Id)

	return 0
}

func getReadableVersion(version string) string {
	return fmt.Sprintf("0.1.%s", version)
}
