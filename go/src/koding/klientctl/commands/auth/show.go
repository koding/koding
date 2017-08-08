package auth

import (
	"fmt"
	"text/tabwriter"

	"koding/klientctl/commands/cli"
	"koding/klientctl/endpoint/auth"

	"github.com/spf13/cobra"
)

type showOptions struct {
	jsonOutput bool
}

// NewShowCommand creates a command that displays current session details.
func NewShowCommand(c *cli.CLI) *cobra.Command {
	opts := &showOptions{}

	cmd := &cobra.Command{
		Use:   "show",
		Short: "Show current session details",
		RunE:  showCommand(c, opts),
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

func showCommand(c *cli.CLI, opts *showOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		info := auth.Used()

		if opts.jsonOutput {
			cli.PrintJSON(c.Out(), info)
		} else {
			printInfo(c, info)
		}

		return nil
	}
}

func printInfo(c *cli.CLI, info *auth.Info) {
	w := tabwriter.NewWriter(c.Out(), 2, 0, 2, ' ', 0)
	defer w.Flush()

	team := "-"
	if info.Session != nil && info.Session.Team != "" {
		team = info.Session.Team
	}

	fmt.Fprintln(w, "USERNAME\tTEAM\tBASEURL")
	fmt.Fprintf(w, "%s\t%s\t%s\n", info.Username, team, info.BaseURL)
}
