package machine

import (
	"koding/klientctl/commands/cli"
	"koding/klientctl/commands/machine/config"
	"koding/klientctl/commands/machine/mount"

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
		config.NewCommand(c),
		NewCpCommand(c),
		NewExecCommand(c),
		NewListCommand(c),
		NewIdentifiersCommand(c),
		mount.NewCommand(c),
		NewSSHCommand(c),
		NewStartCommand(c),
		NewStopCommand(c),
		NewUmountCommand(c),
	)

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.NoArgs, // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}
