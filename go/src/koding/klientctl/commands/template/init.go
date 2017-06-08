package template

import (
	"koding/klientctl/commands/cli"
	"koding/klientctl/config"

	"github.com/spf13/cobra"
)

type initOptions struct {
	output   string
	provider string
	defaults bool
}

// NewInitCommand creates a command that generates a new stack template.
func NewInitCommand(c *cli.CLI, aliasPath ...string) *cobra.Command {
	opts := &initOptions{}

	cmd := &cobra.Command{
		Use:   "init",
		Short: "Generate a new stack template file",
		RunE:  initCommand(c, opts),
	}

	// Flags.
	flags := cmd.Flags()
	flags.StringVarP(&opts.output, "output", "o", config.Konfig.Template.File, "output filename")
	flags.StringVarP(&opts.provider, "provider", "p", "", "cloud provider to use")
	flags.BoolVar(&opts.defaults, "defaults", false, "use default values for stack vars")

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.WithMetrics(aliasPath...), // Gather statistics for this command.
		cli.NoArgs, // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func initCommand(c *cli.CLI, opts *initOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		return nil
	}
}
