package daemon

import (
	"koding/klientctl/commands/cli"
	"koding/klientctl/daemon"

	"github.com/spf13/cobra"
)

type restartOptions struct{}

// NewRestartCommand creates a command that is used to restart deamon service.
func NewRestartCommand(c *cli.CLI) *cobra.Command {
	opts := &restartOptions{}

	cmd := &cobra.Command{
		Use:   "restart",
		Short: "Restart the deamon service",
		RunE:  restartCommand(c, opts),
	}

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.DaemonRequired, // Deamon service is required.
		cli.AdminRequired,  // Root privileges are required.
		cli.NoArgs,         // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func restartCommand(c *cli.CLI, opts *restartOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		return daemon.Restart()
	}
}
