package main

import (
	"encoding/json"
	"fmt"
	"os"
	"text/tabwriter"

	"koding/klientctl/app"
	"koding/klientctl/endpoint/remoteapi"
	"koding/klientctl/endpoint/team"
	"koding/remoteapi/models"

	"github.com/koding/logging"
	cli "gopkg.in/urfave/cli.v1"
)

func StackCreate(c *cli.Context, log logging.Logger, _ string) (int, error) {
	opts := &app.StackOptions{
		Team:        c.String("team"),
		Title:       c.String("title"),
		Credentials: c.StringSlice("credential"),
		File:        c.String("file"),
	}

	if _, _, err := app.BuildStack(opts); err != nil {
		return 1, err
	}

	return 0, nil
}

func StackList(c *cli.Context, log logging.Logger, _ string) (int, error) {
	f := &remoteapi.Filter{
		Team: c.String("team"),
	}

	if f.Team == "" {
		f.Team = team.Used().Name
	}

	stacks, err := remoteapi.ListStacks(f)
	if err != nil {
		return 1, err
	}

	if c.Bool("json") {
		enc := json.NewEncoder(os.Stdout)
		enc.SetEscapeHTML(false)
		enc.SetIndent("", "\t")
		enc.Encode(stacks)

		return 0, nil
	}

	printStacks(stacks)

	return 0, nil
}

func printStacks(stacks []*models.JComputeStack) {
	w := tabwriter.NewWriter(os.Stdout, 2, 0, 2, ' ', 0)
	defer w.Flush()

	fmt.Fprintln(w, "ID\tTITLE\tOWNER\tTEAM\tSTATE\tREVISION")

	for _, stack := range stacks {
		owner := *stack.OriginID
		if owner != "" {
			if account, err := remoteapi.Account(&models.JAccount{ID: owner}); err == nil && account != nil && account.Profile != nil {
				owner = account.Profile.Nickname
			}
		}

		fmt.Fprintf(w, "%s\t%s\t%s\t%s\t%s\t%s\n", stack.ID, str(stack.Title), owner, str(stack.Group), state(stack.Status), stack.StackRevision)
	}
}

func state(status *models.JComputeStackStatus) string {
	if status == nil {
		return "-"
	}
	return status.State
}
