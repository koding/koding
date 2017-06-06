package auth

import (
	"koding/klientctl/commands/cli"

	"github.com/spf13/cobra"
)

// NewCommand creates a command that manages authentication process.
func NewCommand(c *cli.CLI) *cobra.Command {
	cmd := &cobra.Command{
		Use:   "auth",
		Short: "User authorization",
		RunE:  cli.PrintHelp(c.Err()),
	}

	// Subcommands.
	cmd.AddCommand(
		NewLoginCommand(c),
		NewShowCommand(c),
		NewRegisterCommand(c),
	)

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.ApplyForAll(cli.DaemonRequired), // All commands require daemon to be installed.
		cli.NoArgs,                          // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}
