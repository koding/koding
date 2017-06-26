package team

import (
	"fmt"
	"text/tabwriter"

	"koding/kites/kloud/stack"
	"koding/klientctl/commands/cli"
	"koding/klientctl/endpoint/kloud"
	"koding/klientctl/endpoint/team"

	"github.com/spf13/cobra"
)

type whoAmIOptions struct {
	jsonOutput bool
}

// NewWhoAmICommand creates a command that displays authentication details.
func NewWhoAmICommand(c *cli.CLI) *cobra.Command {
	opts := &whoAmIOptions{}

	cmd := &cobra.Command{
		Use:   "whoami",
		Short: "Display authentication details",
		RunE:  whoAmICommand(c, opts),
	}

	// Flags.
	flags := cmd.Flags()
	flags.BoolVar(&opts.jsonOutput, "json", false, "output in JSON format")

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.DaemonRequired, // Deamon service is required.
		cli.NoArgs,         // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func whoAmICommand(c *cli.CLI, opts *whoAmIOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		resp, err := team.Whoami()
		if err != nil {
			return err
		}

		if opts.jsonOutput {
			cli.PrintJSON(c.Out(), resp)
			return nil
		}

		printWhoami(c, resp)

		return nil
	}
}

func printWhoami(c *cli.CLI, resp *stack.WhoamiResponse) {
	t := resp.Team
	w := tabwriter.NewWriter(c.Out(), 2, 0, 2, ' ', 0)
	defer w.Flush()

	fmt.Fprintln(w, "USERNAME\tTEAM\tSLUG\tPRIVACY\tSUBSCRIPTION")

	fmt.Fprintf(w, "%s\t%s\t%s\t%s\t%s\n", kloud.Username(), t.Name, t.Slug, t.Privacy, t.SubStatus)
}
