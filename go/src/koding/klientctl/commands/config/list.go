package config

import (
	"fmt"
	"text/tabwriter"

	konfig "koding/kites/config"
	"koding/kites/config/configstore"
	"koding/klientctl/commands/cli"

	"github.com/spf13/cobra"
)

type listOptions struct {
	jsonOutput bool
}

// NewListCommand creates a command that shows all available configurations.
func NewListCommand(c *cli.CLI) *cobra.Command {
	opts := &listOptions{}

	cmd := &cobra.Command{
		Use:     "list",
		Aliases: []string{"ls"},
		Short:   "List available configurations",
		RunE:    listCommand(c, opts),
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

func listCommand(c *cli.CLI, opts *listOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		konfigs := configstore.List()

		if opts.jsonOutput {
			cli.PrintJSON(c.Out(), konfigs)
			return nil
		}

		printKonfigs(c, konfigs.Slice())

		return nil
	}
}

func printKonfigs(c *cli.CLI, konfigs []*konfig.Konfig) {
	w := tabwriter.NewWriter(c.Out(), 2, 0, 2, ' ', 0)
	defer w.Flush()

	fmt.Fprintln(w, "ID\tKODING URL")

	for _, konfig := range konfigs {
		fmt.Fprintf(w, "%s\t%s\n", konfig.ID(), konfig.KodingPublic())
	}
}
