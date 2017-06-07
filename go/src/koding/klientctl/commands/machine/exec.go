package machine

import (
	"koding/klientctl/commands/cli"

	"github.com/spf13/cobra"
)

type execOptions struct{}

// NewExecCommand creates a command that can run arbitrary command on remote
// machine.
func NewExecCommand(c *cli.CLI) *cobra.Command {
	opts := &execOptions{}

	cmd := &cobra.Command{
		Use:   "exec",
		Short: "Run a command on remote host",
		RunE:  execCommand(c, opts),
	}

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.NoArgs, // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func execCommand(c *cli.CLI, opts *execOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		return nil
	}
}
