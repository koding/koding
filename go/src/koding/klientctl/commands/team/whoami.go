package team

import (
	"koding/klientctl/commands/cli"

	"github.com/spf13/cobra"
)

type whoAmIOptions struct {
	jsonOutput bool
}

// NewWhoAmICommand creates a command that displays authentication details.
func NewWhoAmICommand(c *cli.CLI, aliasPath ...string) *cobra.Command {
	opts := &whoAmIOptions{}

	cmd := &cobra.Command{
		Use:   "whoami",
		Short: "Display authentication details",
		RunE:  whoAmICommand(c, opts),
	}

	// Flags.
	flags := cmd.Flags()
	flags.BoolVar(&opts.jsonOutput, "json", false, "output in JSON format")

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.WithMetrics(aliasPath...), // Gather statistics for this command.
		cli.NoArgs, // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func whoAmICommand(c *cli.CLI, opts *whoAmIOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		return nil
	}
}
