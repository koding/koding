package machine

import (
	"errors"

	"koding/klientctl/commands/cli"
	"koding/klientctl/endpoint/machine"

	"github.com/spf13/cobra"
)

type umountOptions struct {
	all   bool
	force bool
}

// NewUmountCommand creates a command that unmounts mounted directory.
func NewUmountCommand(c *cli.CLI) *cobra.Command {
	opts := &umountOptions{}

	cmd := &cobra.Command{
		Use:     "umount (<mount-id> | <mount-path>)...",
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
		cli.DaemonRequired, // Deamon service is required.
	)(c, cmd)

	return cmd
}

func umountCommand(c *cli.CLI, opts *umountOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		if !opts.all && len(args) == 0 {
			return errors.New("no mounts provided")
		}

		umountOpts := &machine.UmountOptions{
			Identifiers: args,
			Force:       opts.force,
			All:         opts.all,
		}

		return machine.Umount(umountOpts)
	}
}
