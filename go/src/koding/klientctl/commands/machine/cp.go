package machine

import (
	"koding/klientctl/commands/cli"

	"github.com/spf13/cobra"
)

type cpOptions struct{}

// NewCpCommand creates a command that allows to copy files between machines.
func NewCpCommand(c *cli.CLI, aliasPath ...string) *cobra.Command {
	opts := &cpOptions{}

	cmd := &cobra.Command{
		Use:   "cp",
		Short: "Copy file(s) between machines",
		RunE:  cpCommand(c, opts),
	}

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.DaemonRequired,            // Deamon service is required.
		cli.WithMetrics(aliasPath...), // Gather statistics for this command.
		cli.NoArgs,                    // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func cpCommand(c *cli.CLI, opts *cpOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		return nil
	}
}
