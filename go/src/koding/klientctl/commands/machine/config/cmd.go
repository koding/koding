package config

import (
	"koding/klientctl/commands/cli"

	"github.com/spf13/cobra"
)

// NewCommand creates a command that manages remote machine configuration.
func NewCommand(c *cli.CLI) *cobra.Command {
	cmd := &cobra.Command{
		Use:   "config",
		Short: "Manage remote machine configuration",
		RunE:  cli.PrintHelp(c.Err()),
	}

	// Subcommands.
	cmd.AddCommand(
		NewSetCommand(c),
		NewShowCommand(c),
	)

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.NoArgs, // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}
