package cred

import (
	"koding/klientctl/commands/cli"

	"github.com/spf13/cobra"
)

// NewCommand creates a command that manages stack credentials.
func NewCommand(c *cli.CLI) *cobra.Command {
	cmd := &cobra.Command{
		Use:     "credential",
		Aliases: []string{"c"},
		Short:   "Manage stack credentials",
		RunE:    cli.PrintHelp(c.Err()),
	}

	// Subcommands.
	cmd.AddCommand(
		NewCreateCommand(c),
		NewDescribeCommand(c),
		NewInitCommand(c),
		NewListCommand(c),
		NewUseCommand(c),
	)

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.NoArgs, // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}
