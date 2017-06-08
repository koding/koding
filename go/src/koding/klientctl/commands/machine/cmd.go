package machine

import (
	"koding/klientctl/commands/cli"
	"koding/klientctl/commands/machine/config"
	"koding/klientctl/commands/machine/mount"

	"github.com/spf13/cobra"
)

// NewCommand creates a command that manages remote machines.
func NewCommand(c *cli.CLI, aliasPath ...string) *cobra.Command {
	cmd := &cobra.Command{
		Use:   "machine",
		Short: "Manage remote machines",
		RunE:  cli.PrintHelp(c.Err()),
	}

	// Subcommands.
	cmd.AddCommand(
		config.NewCommand(c, cli.ExtendAlias(cmd, aliasPath)...),
		NewCpCommand(c, cli.ExtendAlias(cmd, aliasPath)...),
		NewExecCommand(c, cli.ExtendAlias(cmd, aliasPath)...),
		NewListCommand(c, cli.ExtendAlias(cmd, aliasPath)...),
		mount.NewCommand(c, cli.ExtendAlias(cmd, aliasPath)...),
		NewSSHCommand(c, cli.ExtendAlias(cmd, aliasPath)...),
		NewStartCommand(c, cli.ExtendAlias(cmd, aliasPath)...),
		NewStopCommand(c, cli.ExtendAlias(cmd, aliasPath)...),
		NewUmountCommand(c, cli.ExtendAlias(cmd, aliasPath)...),
	)

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.NoArgs, // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}
