package metrics

import (
	"koding/klientctl/commands/cli"

	"github.com/spf13/cobra"
)

type addOptions struct {
	typ   string
	name  string
	count float64
}

// NewAddCommand creates a command that allows to add new metric.
func NewAddCommand(c *cli.CLI) *cobra.Command {
	opts := &addOptions{}

	cmd := &cobra.Command{
		Use:   "add",
		Short: "Add new metric",
		RunE:  addCommand(c, opts),
	}

	// Flags.
	flags := cmd.Flags()
	flags.StringVar(&opts.typ, "type", "", "metric type")
	flags.StringVar(&opts.name, "name", "", "metric name")
	flags.Float64(&opts.count, "count", "", "metric value")

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.NoArgs, // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func addCommand(c *cli.CLI, opts *addOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		// TODO
		return nil
	}
}
