package daemon

import (
	"koding/klientctl/commands/cli"

	"github.com/spf13/cobra"
)

type stopOptions struct{}

// NewStopCommand creates a command that is used to stop deamon service.
func NewStopCommand(c *cli.CLI, aliasPath ...string) *cobra.Command {
	opts := &stopOptions{}

	cmd := &cobra.Command{
		Use:   "stop",
		Short: "Stop the deamon service",
		RunE:  stopCommand(c, opts),
	}

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.DaemonRequired,            // Deamon service is required.
		cli.AdminRequired,             // Root privileges are required.
		cli.WithMetrics(aliasPath...), // Gather statistics for this command.
		cli.NoArgs,                    // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func stopCommand(c *cli.CLI, opts *stopOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		return nil
	}
}
