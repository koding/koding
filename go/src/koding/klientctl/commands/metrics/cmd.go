package metrics

import (
	"koding/klientctl/commands/cli"

	"github.com/spf13/cobra"
)

// NewCommand creates a command that allows to manually publish events from
// external sources.
func NewCommand(c *cli.CLI) *cobra.Command {
	cmd := &cobra.Command{
		Use:    "metrics",
		Short:  "Publish events from external sources",
		Hidden: true,
		RunE:   cli.PrintHelp(c.Err()),
	}

	// Subcommands.
	cmd.AddCommand(
		NewAddCommand(c),
	)

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.ApplyForAll(cli.DaemonRequired), // All commands require daemon to be installed.
		cli.NoArgs,                          // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}
