package bug

import (
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
		cli.NoArgs, // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func command(c *cli.CLI, opts *options) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		return nil
	}
}
