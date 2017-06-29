package cli

import (
	"github.com/spf13/cobra"
)

type options struct{}

// NewCommand creates a command that displays debug information specific to
// command line interface. It allows to examine requirements of all application
// commands.
func NewCommand(c *CLI) *cobra.Command {
	opts := &options{}

	cmd := &cobra.Command{
		Use:    "cli",
		Short:  "Display CLI status",
		RunE:   command(c, opts),
		Hidden: true,
	}

	// Subcommands.
	cmd.AddCommand(
		NewAutocompleteCommand(c),
	)

	// Middlewares.
	MultiCobraCmdMiddleware(
		NoArgs, // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func command(c *CLI, _ *options) CobraFuncE {
	return func(_ *cobra.Command, _ []string) error {
		PrintJSON(c.Out(), c.Middlewares())
		return nil
	}
}
