package config

import (
	"koding/klientctl/commands/cli"

	"github.com/spf13/cobra"
)

type useOptions struct{}

// NewUseCommand creates a command that can change currently active configuration.
func NewUseCommand(c *cli.CLI) *cobra.Command {
	opts := &useOptions{}

	cmd := &cobra.Command{
		Use:   "use",
		Short: "Change active configuration",
		RunE:  useCommand(c, opts),
	}

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.NoArgs, // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func useCommand(c *cli.CLI, opts *useOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		return nil
	}
}
