package template

import (
	"koding/klientctl/commands/cli"

	"github.com/spf13/cobra"
)

type deleteOptions struct {
	template string
	id       string
	force    bool
}

// NewDeleteCommand creates a command that is used to delete stack templates.
func NewDeleteCommand(c *cli.CLI, aliasPath ...string) *cobra.Command {
	opts := &deleteOptions{}

	cmd := &cobra.Command{
		Use:   "delete",
		Short: "Delete a stack template",
		RunE:  deleteCommand(c, opts),
	}

	// Flags.
	flags := cmd.Flags()
	flags.StringVarP(&opts.template, "template", "t", "", "limit to template name")
	flags.StringVar(&opts.id, "id", "", "limit to template id")
	flags.BoolVar(&opts.force, "force", false, "confirm all questions")

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.DaemonRequired,            // Deamon service is required.
		cli.WithMetrics(aliasPath...), // Gather statistics for this command.
		cli.NoArgs,                    // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func deleteCommand(c *cli.CLI, opts *deleteOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		return nil
	}
}
