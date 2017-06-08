package machine

import (
	"koding/klientctl/commands/cli"

	"github.com/spf13/cobra"
)

type umountOptions struct {
	all   bool
	force bool
}

// NewUmountCommand creates a command that unmounts mounted directory.
func NewUmountCommand(c *cli.CLI, aliasPath ...string) *cobra.Command {
	opts := &umountOptions{}

	cmd := &cobra.Command{
		Use:     "umount",
		Aliases: []string{"unmount", "u"},
		Short:   "Unmount remote directory",
		RunE:    umountCommand(c, opts),
	}

	// Flags.
	flags := cmd.Flags()
	flags.BoolVarP(&opts.all, "all", "a", false, "unmount all")
	flags.BoolVarP(&opts.force, "force", "f", false, "execute all unmount steps")

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.DaemonRequired,            // Deamon service is required.
		cli.WithMetrics(aliasPath...), // Gather statistics for this command.
		cli.NoArgs,                    // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func umountCommand(c *cli.CLI, opts *umountOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		return nil
	}
}
