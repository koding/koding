package machine

import (
	"koding/klientctl/commands/cli"

	"github.com/spf13/cobra"
)

type execOptions struct{}

// NewExecCommand creates a command that can run arbitrary command on remote
// machine.
func NewExecCommand(c *cli.CLI, aliasPath ...string) *cobra.Command {
	opts := &execOptions{}

	cmd := &cobra.Command{
		Use:     "exec",
		Aliases: []string{"e"},
		Short:   "Run a command on remote host",
		RunE:    execCommand(c, opts),
	}

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.DaemonRequired,            // Deamon service is required.
		cli.WithMetrics(aliasPath...), // Gather statistics for this command.
		cli.NoArgs,                    // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func execCommand(c *cli.CLI, opts *execOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		return nil
	}
}
