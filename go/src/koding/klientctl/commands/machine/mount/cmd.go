package machine

import (
	"koding/klientctl/commands/cli"

	"github.com/spf13/cobra"
)

// NewCommand creates a command that manages remote machines.
func NewCommand(c *cli.CLI) *cobra.Command {
	cmd := &cobra.Command{
		Use:   "machine",
		Short: "Manage remote machines",
		RunE:  cli.PrintHelp(c.Err()),
	}

	// Subcommands.
	cmd.AddCommand(
		NewListCommand(c),
	)

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.ApplyForAll(cli.DaemonRequired), // All commands require daemon to be installed.
		cli.NoArgs,                          // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}
