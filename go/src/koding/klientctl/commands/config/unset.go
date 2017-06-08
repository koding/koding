package config

import (
	"koding/klientctl/commands/cli"

	"github.com/spf13/cobra"
)

type unsetOptions struct{}

// NewUnsetCommand creates a command that unsets configuration key, restoring
// it to the default value.
func NewUnsetCommand(c *cli.CLI, aliasPath ...string) *cobra.Command {
	opts := &unsetOptions{}

	cmd := &cobra.Command{
		Use:   "unset",
		Short: "Set a default value for the given key",
		RunE:  unsetCommand(c, opts),
	}

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.WithMetrics(aliasPath...), // Gather statistics for this command.
		cli.NoArgs, // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func unsetCommand(c *cli.CLI, opts *unsetOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		return nil
	}
}
