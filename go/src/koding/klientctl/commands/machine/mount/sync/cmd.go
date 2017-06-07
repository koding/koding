package sync

import (
	"time"

	"koding/klientctl/commands/cli"

	"github.com/spf13/cobra"
)

type options struct {
	timeout time.Duration
}

// NewCommand creates a command that manages mount file synchronization.
func NewCommand(c *cli.CLI) *cobra.Command {
	opts := &options{}

	cmd := &cobra.Command{
		Use:   "sync",
		Short: "Manage mounted files synchronization",
		RunE:  command(c, opts),
	}

	// Subcommands.
	cmd.AddCommand(
		NewPauseCommand(c),
		NewResumeCommand(c),
	)

	// Flags.
	flags := cmd.Flags()
	flags.DurationVar(&opts.timeout, "timeout", time.Minute, "max amount of time to wait")

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
