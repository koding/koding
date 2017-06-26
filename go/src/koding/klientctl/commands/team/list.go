package team

import (
	"fmt"
	"text/tabwriter"

	"koding/kites/kloud/team"
	"koding/klientctl/commands/cli"
	epteam "koding/klientctl/endpoint/team"

	"github.com/spf13/cobra"
)

type listOptions struct {
	slug       string
	jsonOutput bool
}

// NewListCommand creates a command that lists user's teams.
func NewListCommand(c *cli.CLI) *cobra.Command {
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
		cli.DaemonRequired, // Deamon service is required.
		cli.NoArgs,         // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func listCommand(c *cli.CLI, opts *listOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		listOpts := &epteam.ListOptions{
			Slug: opts.slug,
		}

		teams, err := epteam.List(listOpts)
		if err != nil {
			return err
		}

		if len(teams) == 0 {
			if listOpts.Slug == "" {
				fmt.Fprintf(c.Err(), "You do not belong to any team.\n")
				return nil
			}

			fmt.Fprintf(c.Err(), "Cannot find %q team.\n", listOpts.Slug)
			return nil
		}

		if opts.jsonOutput {
			cli.PrintJSON(c.Out(), teams)
			return nil
		}

		printTeams(c, teams)
		return nil
	}
}

func printTeams(c *cli.CLI, teams []*team.Team) {
	w := tabwriter.NewWriter(c.Out(), 2, 0, 2, ' ', 0)
	defer w.Flush()

	fmt.Fprintln(w, "NAME\tSLUG\tPRIVACY\tSUBSCRIPTION")

	for _, t := range teams {
		fmt.Fprintf(w, "%s\t%s\t%s\t%s\n", t.Name, t.Slug, t.Privacy, t.SubStatus)
	}
}
