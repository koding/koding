package sync

import (
	"koding/klientctl/commands/cli"

	"github.com/spf13/cobra"
)

type pauseOptions struct{}

// NewPauseCommand creates a command that allows to pause mount synchronization.
func NewPauseCommand(c *cli.CLI, aliasPath ...string) *cobra.Command {
	opts := &pauseOptions{}

	cmd := &cobra.Command{
		Use:   "pause",
		Short: "Pause file synchronization",
		RunE:  pauseCommand(c, opts),
	}

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.DaemonRequired,            // Deamon service is required.
		cli.WithMetrics(aliasPath...), // Gather statistics for this command.
		cli.NoArgs,                    // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func pauseCommand(c *cli.CLI, opts *pauseOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		return nil
	}
}
