package main

import (
	"encoding/json"
	"fmt"
	"koding/klientctl/endpoint/team"
	"os"

	"github.com/codegangsta/cli"
	"github.com/koding/logging"
)

func TeamShow(c *cli.Context, log logging.Logger, _ string) (int, error) {
	t := team.Used()

	if err := t.Valid(); err != nil {
		fmt.Fprintln(os.Stderr, `You are not currently logged in to any team.\n\nPlease log in first with "kd auth login".`)
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
