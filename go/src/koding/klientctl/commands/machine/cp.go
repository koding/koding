package machine

import (
	"koding/klientctl/commands/cli"

	"github.com/spf13/cobra"
)

type cpOptions struct{}

// NewCpCommand creates a command that allows to copy files between machines.
func NewCpCommand(c *cli.CLI) *cobra.Command {
	opts := &cpOptions{}

	cmd := &cobra.Command{
		Use:   "cp",
		Short: "Copy file(s) between machines",
		RunE:  cpCommand(c, opts),
	}

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.NoArgs, // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func cpCommand(c *cli.CLI, opts *cpOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		return nil
	}
}
