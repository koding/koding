package daemon

import (
	"koding/klientctl/commands/cli"
	"koding/klientctl/daemon"

	"github.com/spf13/cobra"
)

type uninstallOptions struct {
	force bool
}

// NewUninstallCommand creates a command that is used to remove the deamon and
// all other dependencies.
func NewUninstallCommand(c *cli.CLI) *cobra.Command {
	opts := &uninstallOptions{}

	cmd := &cobra.Command{
		Use:   "uninstall",
		Short: "Uninstall the deamon and its dependencies",
		RunE:  uninstallCommand(c, opts),
	}

	// Flags.
	flags := cmd.Flags()
	flags.BoolVarP(&opts.force, "force", "f", false, "execute all uninstallation steps")

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.AdminRequired, // Root privileges are required.s
		cli.NoArgs,        // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func uninstallCommand(c *cli.CLI, opts *uninstallOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		daemonOpts := &daemon.Opts{
			Force: opts.force,
		}

		return daemon.Uninstall(daemonOpts)
	}
}
