package config

import (
	"koding/klientctl/commands/cli"

	"github.com/spf13/cobra"
)

type setOptions struct{}

// NewSetCommand creates a command that allows to set configuration field.
func NewSetCommand(c *cli.CLI, aliasPath ...string) *cobra.Command {
	opts := &setOptions{}

	cmd := &cobra.Command{
		Use:   "set",
		Short: "Set configuration value",
		RunE:  setCommand(c, opts),
	}

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.DaemonRequired,            // Deamon service is required.
		cli.WithMetrics(aliasPath...), // Gather statistics for this command.
		cli.NoArgs,                    // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func setCommand(c *cli.CLI, opts *setOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		return nil
	}
}
