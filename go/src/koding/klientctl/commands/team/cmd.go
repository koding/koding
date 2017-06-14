package team

import (
	"koding/klientctl/commands/cli"

	"github.com/spf13/cobra"
)

// NewCommand creates a command that can list teams and set team context.
func NewCommand(c *cli.CLI, aliasPath ...string) *cobra.Command {
	cmd := &cobra.Command{
		Use:   "team",
		Short: "List available teams and set their context",
		RunE:  cli.PrintHelp(c.Err()),
	}

	// Subcommands.
	cmd.AddCommand(
		NewListCommand(c, cli.ExtendAlias(cmd, aliasPath)...),
		NewShowCommand(c, cli.ExtendAlias(cmd, aliasPath)...),
		NewUseCommand(c, cli.ExtendAlias(cmd, aliasPath)...),
		NewWhoAmICommand(c, cli.ExtendAlias(cmd, aliasPath)...),
	)

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.NoArgs, // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}
