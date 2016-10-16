package main

import (
	"errors"
	"fmt"
	"io/ioutil"
	"koding/kites/kloud/stack"
	"koding/klient/storage"
	"os"
	"sort"
	"time"

	"github.com/codegangsta/cli"
	"github.com/koding/logging"
)

type Stacks []*stack.StackItem

func (s Stacks) ByID(id string) *stack.StackItem {
	for _, stack := range s {
		if stack.ID == id {
			return stack
		}
	}

	return nil
}

func (s Stacks) ByTeam(team string) Stacks {
	var stacks Stacks

	for _, stack := range s {
		if stack.Team != team {
			continue
		}

		stacks = append(stacks, stack)
	}

	return stacks
}

func (s Stacks) Teams() []string {
	var teams []string
	var uniq = make(map[string]struct{})

	for _, stack := range s {
		if _, ok := uniq[stack.Team]; ok {
			continue
		}

		teams = append(teams, stack.Team)
		uniq[stack.Team] = struct{}{}
	}

	sort.Strings(teams)

	return teams
}

func StackCreate(c *cli.Context, log logging.Logger, _ string) (int, error) {
	debug = c.Bool("debug")

	ident := c.String("credential")

	req := &stack.ImportRequest{
		Team:     c.String("team"),
		Provider: c.String("provider"),
		Title:    c.String("title"),
	}

	var credentials Credentials

	switch err := Cache().GetValue("credentials", &credentials); err {
	case nil:
	case storage.ErrKeyNotFound:
		fmt.Fprintln(os.Stderr, `You did not import any credentials yet. Please run "kd credential import".`)

		return 1, err
	default:
		return 1, err
	}

	if ident != "" {
		cred, ok := credentials.ByIdent[ident]
		if !ok {
			fmt.Fprintf(os.Stderr, "Credential %s was not found. You may want to update your credential cache"+
				` with "kd credentials import".`, ident)

			return 1, nil
		}

		req.Credentials = map[string][]string{
			cred.Provider: {cred.Identifier},
		}
	} else {
		req.Credentials = make(map[string][]string, len(credentials.Defaults))

		for provider, ident := range credentials.Defaults {
			req.Credentials[provider] = []string{ident}
		}
	}

	var err error

	switch file := c.String("file"); file {
	case "":
		fmt.Fprintln(os.Stderr, "No stack template file was provided.")
		return 1, errors.New("no stack template file was provided")
	case "-":
		req.Template, err = ioutil.ReadAll(os.Stdin)
	default:
		req.Template, err = ioutil.ReadFile(file)
	}

	if err != nil {
		fmt.Fprintln(os.Stderr, "Error reading stack template file:", err)
		return 1, err
	}

	var stacks Stacks

	if err := Cache().GetValue("stacks", &stacks); err != nil && err != storage.ErrKeyNotFound {
		fmt.Fprintln(os.Stderr, "Error reading stacks:", err)
		return 1, err
	}

	kloud, err := Kloud()
	if err != nil {
		fmt.Fprintln(os.Stderr, "Error communicating with Koding:", err)
		return 1, err
	}

	fmt.Println("Creating a stack...")

	r, err := kloud.TellWithTimeout("import", 30*time.Second, req)
	if err != nil {
		fmt.Fprintln(os.Stderr, "Error communicating with Koding:", err)
		return 1, err
	}

	var resp stack.ImportResponse

	if err := r.Unmarshal(&resp); err != nil {
		fmt.Fprintln(os.Stderr, "Error reading import response:", err)
		return 1, err
	}

	if resp.Stack != nil {
		stacks = append(stacks, resp.Stack)

		fmt.Printf("Created %q stack with %s ID.\n", resp.Stack.Title, resp.Stack.ID)
	}

	if err := Cache().SetValue("stacks", stacks); err != nil {
		fmt.Fprintln(os.Stderr, "Error saving stacks:", err)
		return 1, err
	}

	// TODO(rjeczalik): add waiting on a stack build

	return 0, nil
}
