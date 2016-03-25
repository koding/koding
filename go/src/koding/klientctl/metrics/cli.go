package metrics

import (
	"fmt"
	"os"

	"github.com/codegangsta/cli"
	"github.com/koding/logging"
)

func MetricsCommand(c *cli.Context, log logging.Logger, configFolder string) int {
	if len(c.Args()) != 1 {
		fmt.Println("This command is for internal use only.")
		return 1
	}

	// sanity check to prevent users running this command manually
	if c.Args()[0] != "force" {
		fmt.Println("This command is for internal use only.")
		return 1
	}

	m := NewDefaultServer(configFolder, os.Getpid())
	if err := m.Start(); err != nil {
		fmt.Println("Error starting server:", err)
		return 1
	}

	return 0
}
