package cli

import (
	"fmt"

	"github.com/spf13/cobra"
)

// AdminRequired ensures that the user who runs given command has root privileges.
func AdminRequired(cli *CLI, rootCmd *cobra.Command) {
	tail := rootCmd.RunE
	if tail == nil {
		panic("cannot insert middleware into empty function")
	}

	rootCmd.RunE = func(cmd *cobra.Command, args []string) error {
		isAdmin, permErr := cli.IsAdmin()
		if permErr != nil {
			cli.Log().Debug("Cannot obtain user permissions: %v", permErr)
		}

		if isAdmin {
			return tail(cli)
		}

		if permErr != nil {
			// In case of permission error run command anyway.
			return tail(cli)
		}

		return fmt.Errorf("command requires root privileges")
	}
}
