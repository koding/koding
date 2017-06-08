package daemon

import (
	"koding/klientctl/commands/cli"

	"github.com/spf13/cobra"
)

// NewCommand creates a command that manages deamon service.
func NewCommand(c *cli.CLI, aliasPath ...string) *cobra.Command {
	cmd := &cobra.Command{
		Use:   "daemon",
		Short: "Manage deamon service",
		RunE:  cli.PrintHelp(c.Err()),
	}

	// Subcommands.
	cmd.AddCommand(
		NewInstallCommand(c, cli.ExtendAlias(cmd, aliasPath)...),
		NewRestartCommand(c, cli.ExtendAlias(cmd, aliasPath)...),
		NewStartCommand(c, cli.ExtendAlias(cmd, aliasPath)...),
		NewStopCommand(c, cli.ExtendAlias(cmd, aliasPath)...),
		NewUninstallCommand(c, cli.ExtendAlias(cmd, aliasPath)...),
		NewUpdateCommand(c, cli.ExtendAlias(cmd, aliasPath)...),
	)

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.NoArgs, // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}
