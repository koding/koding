package mount

import (
	"koding/klientctl/commands/cli"
	msync "koding/klientctl/commands/machine/mount/sync"

	"github.com/spf13/cobra"
)

type options struct{}

// NewCommand creates a command that allows to create mounts and manage their
// properties.
func NewCommand(c *cli.CLI) *cobra.Command {
	opts := &options{}

	cmd := &cobra.Command{
		Use:     "mount",
		Aliases: []string{"m"},
		Short:   "Mount remote directory",
		RunE:    command(c, opts),
	}

	// Subcommands.
	cmd.AddCommand(
		NewInspectCommand(c),
		NewListCommand(c),
		msync.NewCommand(c),
	)

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.NoArgs, // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func command(c *cli.CLI, opts *options) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		return nil
	}
}
