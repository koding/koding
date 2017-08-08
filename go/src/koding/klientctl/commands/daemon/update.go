package daemon

import (
	"koding/klientctl/commands/cli"
	"koding/klientctl/daemon"

	"github.com/spf13/cobra"
)

type updateOptions struct {
	force  bool
	contin bool // continue - deprecated.
}

// NewUpdateCommand creates a command that can be used to update the service to
// the latest version.
func NewUpdateCommand(c *cli.CLI) *cobra.Command {
	opts := &updateOptions{}

	cmd := &cobra.Command{
		Use:   "update",
		Short: "Update to the latest version",
		RunE:  updateCommand(c, opts),
	}

	// Flags.
	flags := cmd.Flags()
	flags.BoolVar(&opts.force, "force", false, "force retrieving configuration")
	flags.BoolVar(&opts.contin, "continue", false, "internal use only")
	flags.Lookup("continue").Hidden = true

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.DaemonRequired, // Deamon service is required.
		cli.AdminRequired,  // Root privileges are required.
		cli.NoArgs,         // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func updateCommand(c *cli.CLI, opts *updateOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		daemonOpts := &daemon.Opts{
			Force: opts.force,
		}

		return daemon.Update(daemonOpts)
	}
}
