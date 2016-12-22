package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"

	"koding/klientctl/endpoint/auth"
	"koding/klientctl/endpoint/kloud"
	"koding/klientctl/endpoint/team"

	"github.com/codegangsta/cli"
	"github.com/koding/logging"
)

func AuthLogin(c *cli.Context, log logging.Logger, _ string) (int, error) {
	// If we already own a valid kite.key, it means we were already
	// authenticated and we just call kloud using kite.key authentication.
	err := kloud.DefaultClient.Transport.Valid()

	log.Debug("auth: transport test: %s", err)

	if err == nil {
		opts := &auth.LoginOptions{
			Team: c.String("team"),
		}

		session, err := auth.Login(opts)
		if err != nil {
			return 1, fmt.Errorf("error logging into your Koding account: %v", err)
		}

		team.Use(&team.Team{Name: session.Team})

		if c.Bool("json") {
			enc := json.NewEncoder(os.Stdout)
			enc.SetIndent("", "\t")
			enc.Encode(session)
		} else {
			fmt.Fprintf(os.Stderr, "Successfully logged in to %q team.\n", session.Team)
		}

		return 0, nil
	}

	// If we do not have a valid kite.key, we authenticate with user/pass.
	// TODO(rjeczalik): implement user/pass authentication

	fmt.Fprintln(os.Stderr, "Unable to log into your Koding account. Please try again at some later time.")

	return 1, errors.New("user/pass: not implemented")
}
