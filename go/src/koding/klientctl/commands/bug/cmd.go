package bug

import (
	"koding/klientctl/bug"
	"koding/klientctl/commands/cli"

	"github.com/spf13/cobra"
)

type options struct{}

// NewCommand creates a command that allows to report a bug.
func NewCommand(c *cli.CLI) *cobra.Command {
	opts := &options{}

	cmd := &cobra.Command{
		Use:   "bug",
		Short: "Send a bug report",
		RunE:  command(c, opts),
	}

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.DaemonRequired, // Deamon service is required.
		cli.NoArgs,         // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func command(c *cli.CLI, _ *options) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		return bug.Bug(c)
	}
}
