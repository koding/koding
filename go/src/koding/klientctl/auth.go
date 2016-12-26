package main

import (
	"encoding/json"
	"fmt"
	"net/url"
	"os"

	"koding/kites/config"
	"koding/kites/config/configstore"
	"koding/kites/kloud/stack"
	"koding/klientctl/endpoint/auth"
	"koding/klientctl/endpoint/kloud"
	"koding/klientctl/endpoint/team"
	"koding/klientctl/helper"

	"github.com/codegangsta/cli"
	"github.com/koding/logging"
)

func AuthLogin(c *cli.Context, log logging.Logger, _ string) (int, error) {
	kodingURL, err := url.Parse(c.String("koding"))
	if err != nil {
		return 1, fmt.Errorf("%q is not a valid URL value: %s\n", c.String("koding"), err)
	}

	k, existing := configstore.List()[config.ID(kodingURL.String())]
	if !existing {
		k = &config.Konfig{
			Endpoints: &config.Endpoints{
				Koding: config.NewEndpointURL(kodingURL),
			},
		}
	}

	if err := configstore.Use(k); err != nil {
		return 1, err
	}

	// We create here a kloud client instead of using kloud.DefaultClient
	// in order to handle first-time login attempts where configuration
	// for kloud does not yet exist.
	kloudClient := &kloud.Client{
		Transport: &kloud.KiteTransport{
			Konfig: k,
			Log:    log,
		},
	}

	authClient := &auth.Client{
		Kloud: kloudClient,
	}

	teamClient := &team.Client{
		Kloud: kloudClient,
	}

	// If we already own a valid kite.key, it means we were already
	// authenticated and we just call kloud using kite.key authentication.
	err = kloudClient.Transport.(stack.Validator).Valid()

	log.Debug("auth: transport test: %s", err)

	var session *auth.Session

	if err == nil {
		opts := &auth.LoginOptions{
			Team: c.String("team"),
		}

		session, err = authClient.Login(opts)
	} else {
		user, err := helper.Ask("Username [%s]: ", config.CurrentUser.Username)
		if err != nil {
			return 1, err
		}

		if user == "" {
			user = config.CurrentUser.Username
		}

		pass, err := helper.AskSecret("Password [***]: ")
		if err != nil {
			return 1, err
		}

		opts := &auth.LoginOptions{
			Team:     c.String("team"),
			Username: user,
			Password: pass,
		}

		session, err = authClient.Login(opts)
	}

	if err != nil {
		return 1, fmt.Errorf("error logging into your Koding account: %v", err)
	}

	if session.KiteKey != "" {
		k.KiteKey = session.KiteKey

		if err := configstore.Use(k); err != nil {
			return 1, err
		}
	}

	teamClient.Use(&team.Team{Name: session.Team})

	if c.Bool("json") {
		enc := json.NewEncoder(os.Stdout)
		enc.SetIndent("", "\t")
		enc.Encode(session)
	} else {
		fmt.Fprintf(os.Stderr, "Successfully logged in to %q team.\n", session.Team)
	}

	return 0, nil
}
