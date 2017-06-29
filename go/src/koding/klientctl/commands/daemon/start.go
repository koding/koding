package daemon

import (
	"koding/klientctl/commands/cli"
	"koding/klientctl/daemon"

	"github.com/spf13/cobra"
)

type startOptions struct{}

// NewStartCommand creates a command that is used to start service deamon.
func NewStartCommand(c *cli.CLI) *cobra.Command {
	opts := &startOptions{}

	cmd := &cobra.Command{
		Use:   "start",
		Short: "Start the deamon service",
		RunE:  startCommand(c, opts),
	}

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.DaemonRequired, // Deamon service is required.
		cli.AdminRequired,  // Root privileges are required.
		cli.NoArgs,         // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func startCommand(c *cli.CLI, opts *startOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		return daemon.Start()
	}
}
