package main

import (
	"encoding/json"
	"fmt"
	"os"
	"text/tabwriter"

	"koding/kites/kloud/team"
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
		return 0, err
	}

	if len(teams) == 0 {
		if opts.Slug == "" {
			fmt.Fprintln(os.Stderr, "You do not belong to any team.")
			return 0, nil
		} else {
			fmt.Fprintf(os.Stderr, "Cannot find %q team.", opts.Slug)
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

func printTeams(teams []*team.Team) {
	w := tabwriter.NewWriter(os.Stdout, 2, 0, 2, ' ', 0)
	defer w.Flush()

	fmt.Fprintln(w, "NAME\tSLUG\tPRIVACY\tMEMBERS\tSUBSCRIPTION")

	for _, t := range teams {
		fmt.Fprintf(w, "%s\t%s\t%s\t%s\t%s\n", t.Name, t.Slug, t.Privacy, t.Subscription)
	}
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
		fmt.Fprintf(os.Stderr, "You are currently logged in to a %q team.", t.Name)
	}

	return 0, nil
}
