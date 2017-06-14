package config

import (
	"koding/klientctl/commands/cli"

	"github.com/spf13/cobra"
)

type showOptions struct {
	defaults   bool
	jsonOutput bool
}

// NewShowCommand creates a command that displays configurations.
func NewShowCommand(c *cli.CLI, aliasPath ...string) *cobra.Command {
	opts := &showOptions{}

	cmd := &cobra.Command{
		Use:   "show",
		Short: "Show configuration",
		RunE:  showCommand(c, opts),
	}

	// Flags.
	flags := cmd.Flags()
	flags.BoolVar(&opts.defaults, "defaults", false, "include default configuration")
	flags.BoolVar(&opts.jsonOutput, "json", false, "output in JSON format")

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.WithMetrics(aliasPath...), // Gather statistics for this command.
		cli.NoArgs, // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func showCommand(c *cli.CLI, opts *showOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		return nil
	}
}
