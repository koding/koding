package auth

import (
	"koding/klientctl/commands/cli"

	"github.com/spf13/cobra"
)

// NewCommand creates a command that manages authentication process.
func NewCommand(c *cli.CLI, aliasPath ...string) *cobra.Command {
	cmd := &cobra.Command{
		Use:   "auth",
		Short: "User authorization",
		RunE:  cli.PrintHelp(c.Err()),
	}

	// Subcommands.
	cmd.AddCommand(
		NewLoginCommand(c, cli.ExtendAlias(cmd, aliasPath)...),
		NewShowCommand(c, cli.ExtendAlias(cmd, aliasPath)...),

		// Register command is disabled due to: #11027
		// NewRegisterCommand(c, cli.ExtendAlias(cmd, aliasPath)...),
	)

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.NoArgs, // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}
