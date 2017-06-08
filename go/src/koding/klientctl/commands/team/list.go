package team

import (
	"koding/klientctl/commands/cli"

	"github.com/spf13/cobra"
)

type listOptions struct {
	slug       string
	jsonOutput bool
}

// NewListCommand creates a command that lists user's teams.
func NewListCommand(c *cli.CLI, aliasPath ...string) *cobra.Command {
	opts := &listOptions{}

	cmd := &cobra.Command{
		Use:     "list",
		Aliases: []string{"ls"},
		Short:   "List user's teams",
		RunE:    listCommand(c, opts),
	}

	// Flags.
	flags := cmd.Flags()
	flags.StringVar(&opts.slug, "slug", "", "limit to team with given slug")
	flags.BoolVar(&opts.jsonOutput, "json", false, "output in JSON format")

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.DaemonRequired,            // Deamon service is required.
		cli.WithMetrics(aliasPath...), // Gather statistics for this command.
		cli.NoArgs,                    // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func listCommand(c *cli.CLI, opts *listOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		return nil
	}
}
