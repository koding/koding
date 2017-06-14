package team

import (
	"koding/klientctl/commands/cli"

	"github.com/spf13/cobra"
)

type useOptions struct{}

// NewUseCommand creates a command that can switch team context.
func NewUseCommand(c *cli.CLI, aliasPath ...string) *cobra.Command {
	opts := &useOptions{}

	cmd := &cobra.Command{
		Use:   "use",
		Short: "Switch team context",
		RunE:  useCommand(c, opts),
	}

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.DaemonRequired,            // Deamon service is required.
		cli.WithMetrics(aliasPath...), // Gather statistics for this command.
		cli.NoArgs,                    // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func useCommand(c *cli.CLI, opts *useOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		return nil
	}
}
