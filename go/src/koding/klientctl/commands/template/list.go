package template

import (
	"fmt"
	"text/tabwriter"

	"koding/klientctl/commands/cli"
	"koding/klientctl/endpoint/kloud"
	"koding/klientctl/endpoint/remoteapi"
	"koding/remoteapi/models"

	"github.com/spf13/cobra"
)

type listOptions struct {
	template   string
	team       string
	jsonOutput bool
}

// NewListCommand creates a command that displays stack templates.
func NewListCommand(c *cli.CLI) *cobra.Command {
	opts := &listOptions{}

	cmd := &cobra.Command{
		Use:     "list",
		Aliases: []string{"ls"},
		Short:   "List stack templates",
		RunE:    listCommand(c, opts),
	}

	// Flags.
	flags := cmd.Flags()
	flags.StringVarP(&opts.template, "template", "t", "", "limit to template name")
	flags.StringVar(&opts.team, "team", "", "limit to given team")
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
		f := &remoteapi.Filter{
			Slug: opts.template,
			Team: opts.team,
		}

		if f.Slug == "" {
			f.Slug = kloud.Username() + "/"
		}

		tmpls, err := remoteapi.ListTemplates(f)
		if err != nil {
			return err
		}

		if opts.jsonOutput {
			cli.PrintJSON(c.Out(), tmpls)
			return nil
		}

		printTemplates(c, tmpls)

		return nil
	}
}

func printTemplates(c *cli.CLI, templates []*models.JStackTemplate) {
	w := tabwriter.NewWriter(c.Out(), 2, 0, 2, ' ', 0)
	defer w.Flush()

	fmt.Fprintln(w, "ID\tTITLE\tSLUG\tOWNER\tTEAM\tACCESS\tMACHINES")

	for _, tmpl := range templates {
		owner := *tmpl.OriginID
		if owner != "" {
			if account, err := remoteapi.Account(&models.JAccount{ID: owner}); err == nil {
				owner = account.Profile.Nickname
			}
		}

		fmt.Fprintf(w, "%s\t%s\t%s\t%s\t%s\t%s\t%d\n", tmpl.ID, str(tmpl.Title), str(tmpl.Slug), owner, str(tmpl.Group), tmpl.AccessLevel, len(tmpl.Machines))
	}
}

func str(s *string) string {
	if s == nil || *s == "" {
		return "-"
	}
	return *s
}
