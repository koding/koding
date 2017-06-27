package config

import (
	"fmt"

	"koding/kites/config/configstore"
	"koding/klientctl/commands/cli"

	"github.com/spf13/cobra"
)

type setOptions struct{}

// NewSetCommand creates a command that allows to set configuration key value.
func NewSetCommand(c *cli.CLI) *cobra.Command {
	opts := &setOptions{}

	cmd := &cobra.Command{
		Use:   "set <key> <value>",
		Short: "Set a value for the given key",
		RunE:  setCommand(c, opts),
	}

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.ExactArgs(2), // Two arguments are accepted.
	)(c, cmd)

	return cmd
}

func setCommand(c *cli.CLI, opts *setOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		if err := configstore.Set(args[0], args[1]); err != nil {
			return err
		}

		fmt.Fprintf(c.Out(), "Changed %q setting.\n\nPlease run \"sudo kd restart\" for the new configuration to take effect.\n", args[0])

		return nil
	}
}
