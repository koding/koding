package credential

import (
	"koding/klientctl/commands/cli"

	"github.com/spf13/cobra"
)

type describeOptions struct {
	provider string
	jsonOutput bool
}

// NewDescribeCommand creates a command that describes credential documents.
func NewDescribeCommand(c *cli.CLI) *cobra.Command {
	opts := &describeOptions{}

	cmd := &cobra.Command{
		Use:     "describe",
		Short:   "Describe credential document",
		RunE:    describeCommand(c, opts),
	}

	// Flags.
	flags := cmd.Flags()
	flags.StringVarP(&opts.provider, "provider", "p", "", "credential provider")
	flags.BoolVar(&opts.jsonOutput, "json", false, "output in JSON format")

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.NoArgs,                    // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func describeCommand(c *cli.CLI, opts *describeOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		return nil
	}
}
