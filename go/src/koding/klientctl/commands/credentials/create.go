package credential

import (
	"koding/klientctl/commands/cli"

	"github.com/spf13/cobra"
)

type createOptions struct {
	provider string
	file string
	team string
	title string
	jsonOutput bool
}

// NewCreateCommand creates a command that can be used to create new stack
// credential.
func NewCreateCommand(c *cli.CLI) *cobra.Command {
	opts := &createOptions{}

	cmd := &cobra.Command{
		Use:     "create",
		Short:   "Create a new stack credential",
		RunE:    createCommand(c, opts),
	}

	// Flags.
	flags := cmd.Flags()
	flags.StringVarP(&opts.provider, "provider", "p", "", "credential provider")
	flags.StringVar(&opts.file, "file", "", "read from file")
	flags.StringVar(&opts.team, "team", "", "owner of the credential")
	flags.StringVar(&opts.title, "title", "", "credential title")
	flags.BoolVar(&opts.jsonOutput, "json", false, "output in JSON format")

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.NoArgs,                    // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func createCommand(c *cli.CLI, opts *createOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		return nil
	}
}
