package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"text/tabwriter"

	"koding/kites/kloud/stack"
	"koding/kites/kloud/team"
	"koding/klientctl/endpoint/kloud"
	epteam "koding/klientctl/endpoint/team"

	"github.com/codegangsta/cli"
	"github.com/koding/logging"
)

func TeamList(c *cli.Context, log logging.Logger, _ string) (int, error) {
	opts := &epteam.ListOptions{
		Slug: c.String("slug"),
	}

	teams, err := epteam.List(opts)
	if err != nil {
		return 1, err
	}

	if len(teams) == 0 {
		if opts.Slug == "" {
			fmt.Fprintln(os.Stderr, "You do not belong to any team.\n")
			return 0, nil
		} else {
			fmt.Fprintf(os.Stderr, "Cannot find %q team.\n", opts.Slug)
			return 1, nil
		}
	}

	if c.Bool("json") {
		p, err := json.MarshalIndent(teams, "", "\t")
		if err != nil {
			return 1, err
		}

		fmt.Printf("%s\n", p)
		return 0, nil
	}

	printTeams(teams)
	return 0, nil
}

func TeamWhoami(c *cli.Context, _ logging.Logger, _ string) (int, error) {
	resp, err := epteam.Whoami()
	if err != nil {
		return 1, err
	}

	if c.Bool("json") {
		enc := json.NewEncoder(os.Stdout)
		enc.SetIndent("", "\t")
		enc.Encode(resp)

		return 0, nil
	}

	printWhoami(resp)

	return 0, nil
}

func TeamUse(c *cli.Context, _ logging.Logger, _ string) (int, error) {
	ident := c.Args().Get(0)

	if ident == "" {
		cli.ShowCommandHelp(c, "use")
		return 1, errors.New("missing argument")
	}

	teams, err := epteam.List(&epteam.ListOptions{})
	if err != nil {
		return 1, err
	}

	var team *team.Team
	for _, t := range teams {
		if t.Name == ident || t.Slug == ident {
			team = t
			break
		}
	}

	if team == nil {
		return 1, fmt.Errorf("unable to find %q team", ident)
	}

	epteam.Use(&epteam.Team{
		Name: team.Name,
	})

	fmt.Fprintln(os.Stderr, "You are currently logged in to the following team:", team.Name)

	return 0, nil
}

func printTeams(teams []*team.Team) {
	w := tabwriter.NewWriter(os.Stdout, 2, 0, 2, ' ', 0)
	defer w.Flush()

	fmt.Fprintln(w, "NAME\tSLUG\tPRIVACY\tSUBSCRIPTION")

	for _, t := range teams {
		fmt.Fprintf(w, "%s\t%s\t%s\t%s\n", t.Name, t.Slug, t.Privacy, t.SubStatus)
	}
}

func printWhoami(resp *stack.WhoamiResponse) {
	t := resp.Team
	w := tabwriter.NewWriter(os.Stdout, 2, 0, 2, ' ', 0)
	defer w.Flush()

	fmt.Fprintln(w, "USERNAME\tTEAM\tSLUG\tPRIVACY\tSUBSCRIPTION")

	fmt.Fprintln(w, "%s\t%s\t%s\t%s\t%s\n", kloud.Username(), t.Name, t.Slug, t.Privacy, t.SubStatus)
}

func TeamShow(c *cli.Context, log logging.Logger, _ string) (int, error) {
	t := epteam.Used()

	if err := t.Valid(); err != nil {
		fmt.Fprintln(os.Stderr, `You are not currently logged in to any team. Please log in first with "kd auth login".`)
		return 1, err
	}

	if c.Bool("json") {
		enc := json.NewEncoder(os.Stdout)
		enc.SetIndent("", "\t")
		enc.Encode(t)
	} else {
		fmt.Fprintln(os.Stderr, "You are currently logged in to the following team:", t.Name)
	}

	return 0, nil
}
