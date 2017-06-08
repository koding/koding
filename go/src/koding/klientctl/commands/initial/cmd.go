package initial

import (
	"koding/klientctl/commands/cli"

	"github.com/spf13/cobra"
)

type options struct{}

// NewCommand creates a command that initializes new KD project.
func NewCommand(c *cli.CLI, aliasPath ...string) *cobra.Command {
	opts := &options{}

	cmd := &cobra.Command{
		Use:   "init",
		Short: "Initialize a new project",
		RunE:  command(c, opts),
	}

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.DaemonRequired,            // Deamon service is required.
		cli.WithMetrics(aliasPath...), // Gather statistics for this command.
		cli.NoArgs,                    // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func command(c *cli.CLI, opts *options) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		return nil
	}
}
