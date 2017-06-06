package team

import (
	"koding/klientctl/commands/cli"

	"github.com/spf13/cobra"
)

type whoAmIOptions struct {
	jsonOutput bool
}

// NewWhoAmICommand creates a command that displays authentication details.
func NewWhoAmICommand(c *cli.CLI) *cobra.Command {
	opts := &whoAmIOptions{}

	cmd := &cobra.Command{
		Use:   "whoami",
		Short: "List available machines",
		RunE:  whoAmICommand(c, opts),
	}

	// Flags.
	flags := cmd.Flags()
	flags.BoolVar(&opts.jsonOutput, "json", false, "output in JSON format")

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.NoArgs, // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func whoAmICommand(c *cli.CLI, opts *whoAmIOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		return nil
	}
}
