package sync

import (
	"koding/klientctl/commands/cli"

	"github.com/spf13/cobra"
)

type pauseOptions struct{}

// NewPauseCommand creates a command that allows to pause mount synchronization.
func NewPauseCommand(c *cli.CLI) *cobra.Command {
	opts := &pauseOptions{}

	cmd := &cobra.Command{
		Use:   "pause [<mount-id> | <mount-path>]",
		Short: "Pause file synchronization",
		RunE:  pauseCommand(c, opts),
	}

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.DaemonRequired, // Deamon service is required.
		cli.MaxArgs(1),     // At most one argument is accepted.
	)(c, cmd)

	return cmd
}

func pauseCommand(c *cli.CLI, opts *pauseOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		return command(c, &options{pause: true})(cmd, args)
	}
}
