package config

import (
	"koding/klientctl/commands/cli"

	"github.com/spf13/cobra"
)

// NewCommand creates a command that manages KD configuration.
func NewCommand(c *cli.CLI, aliasPath ...string) *cobra.Command {
	cmd := &cobra.Command{
		Use:   "config",
		Short: "Manage tool configuration",
		RunE:  cli.PrintHelp(c.Err()),
	}

	// Subcommands.
	cmd.AddCommand(
		NewListCommand(c, cli.ExtendAlias(cmd, aliasPath)...),
		NewResetCommand(c, cli.ExtendAlias(cmd, aliasPath)...),
		NewSetCommand(c, cli.ExtendAlias(cmd, aliasPath)...),
		NewShowCommand(c, cli.ExtendAlias(cmd, aliasPath)...),
		NewUnsetCommand(c, cli.ExtendAlias(cmd, aliasPath)...),
		NewUseCommand(c, cli.ExtendAlias(cmd, aliasPath)...),
	)

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.NoArgs, // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}
