package config

import (
	"koding/klientctl/commands/cli"

	"github.com/spf13/cobra"
)

type setOptions struct{}

// NewSetCommand creates a command that allows to set configuration key value.
func NewSetCommand(c *cli.CLI) *cobra.Command {
	opts := &setOptions{}

	cmd := &cobra.Command{
		Use:   "set",
		Short: "Set a value for the given key",
		RunE:  setCommand(c, opts),
	}

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.NoArgs, // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func setCommand(c *cli.CLI, opts *setOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		return nil
	}
}
