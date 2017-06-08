package template

import (
	"koding/klientctl/commands/cli"

	"github.com/spf13/cobra"
)

type showOptions struct {
	id         string
	hclOutput  bool
	jsonOutput bool
}

// NewShowCommand creates a command that shows details of a given stack template.
func NewShowCommand(c *cli.CLI, aliasPath ...string) *cobra.Command {
	opts := &showOptions{}

	cmd := &cobra.Command{
		Use:   "show",
		Short: "Show stack template details",
		RunE:  showCommand(c, opts),
	}

	// Flags.
	flags := cmd.Flags()
	flags.StringVar(&opts.id, "id", "", "limit to template id")
	flags.BoolVar(&opts.hclOutput, "hcl", false, "output in HCL format")
	flags.BoolVar(&opts.jsonOutput, "json", false, "output in JSON format")

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.DaemonRequired,            // Deamon service is required.
		cli.WithMetrics(aliasPath...), // Gather statistics for this command.
		cli.NoArgs,                    // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func showCommand(c *cli.CLI, opts *showOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		return nil
	}
}
