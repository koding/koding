package config

import (
	"fmt"

	"koding/kites/config/configstore"
	"koding/klientctl/commands/cli"

	"github.com/spf13/cobra"
)

type unsetOptions struct{}

// NewUnsetCommand creates a command that unsets configuration key, restoring
// it to the default value.
func NewUnsetCommand(c *cli.CLI) *cobra.Command {
	opts := &unsetOptions{}

	cmd := &cobra.Command{
		Use:   "unset <key>",
		Short: "Set a default value for the given key",
		RunE:  unsetCommand(c, opts),
	}

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.ExactArgs(1), // One argument is accepted.
	)(c, cmd)

	return cmd
}

func unsetCommand(c *cli.CLI, opts *unsetOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		arg := args[0]

		if err := configstore.Set(arg, ""); err != nil {
			return err
		}

		fmt.Printf("Changed %q setting.\n\nPlease run \"sudo kd restart\" for the new configuration to take effect.\n", arg)

		return nil
	}
}
