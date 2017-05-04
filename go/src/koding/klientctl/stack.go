package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"io/ioutil"
	"os"
	"text/tabwriter"

	"koding/klientctl/endpoint/kloud"
	"koding/klientctl/endpoint/remoteapi"
	"koding/klientctl/endpoint/stack"
	"koding/klientctl/endpoint/team"
	"koding/remoteapi/models"

	"github.com/codegangsta/cli"
	"github.com/koding/logging"
)

func StackCreate(c *cli.Context, log logging.Logger, _ string) (int, error) {
	var p []byte
	var err error

	switch file := c.String("file"); file {
	case "":
		return 1, errors.New("no template file was provided")
	case "-":
		p, err = ioutil.ReadAll(os.Stdin)
	default:
		p, err = ioutil.ReadFile(file)
	}

	if err != nil {
		return 1, errors.New("error reading template file: " + err.Error())
	}

	fmt.Fprintln(os.Stderr, "Creating stack... ")

	opts := &stack.CreateOptions{
		Team:        c.String("team"),
		Title:       c.String("title"),
		Credentials: c.StringSlice("credential"),
		Template:    p,
	}

	resp, err := stack.Create(opts)
	if err != nil {
		return 1, errors.New("error creating stack: " + err.Error())
	}

	if c.Bool("json") {
		enc := json.NewEncoder(os.Stdout)
		enc.SetIndent("", "\t")
		enc.Encode(resp)

		return 0, nil
	}

	fmt.Fprintf(os.Stderr, "\nCreatad %q stack with %s ID.\nWaiting for the stack to finish building...\n\n", resp.Title, resp.StackID)

	for e := range kloud.Wait(resp.EventID) {
		if e.Error != nil {
			return 1, fmt.Errorf("\nBuilding %q stack failed:\n%s\n", resp.Title, e.Error)
		}

		fmt.Printf("[%d%%] %s\n", e.Event.Percentage, e.Event.Message)
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
