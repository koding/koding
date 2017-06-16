package metrics

import (
	"koding/klientctl/commands/cli"
	"time"

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
	flags.Float64Var(&opts.count, "count", 0, "metric value")

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.NoArgs, // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func addCommand(c *cli.CLI, opts *addOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		// Metrics might be disabled.
		if c.Metrics() == nil || c.Metrics().Datadog == nil {
			return nil
		}

		// Command standard tags.
		tags := append(
			cli.CommandPathTags("cli_external"),
			cli.ApplicationInfoTags()...,
		)

		name := "cli_external_" + opts.name
		switch opts.typ {
		case "counter":
			c.Metrics().Datadog.Count(name, int64(opts.count), tags, 1)
		case "timing":
			c.Metrics().Datadog.Timing(name, time.Duration(opts.count), tags, 1)
		case "gauge":
			c.Metrics().Datadog.Gauge(name, opts.count, tags, 1)
		}

		return nil
	}
}
