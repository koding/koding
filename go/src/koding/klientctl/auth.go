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
	"koding/klientctl/endpoint/kontrol"
	"koding/klientctl/endpoint/team"
	"koding/klientctl/helper"

	"github.com/codegangsta/cli"
	"github.com/koding/logging"
)

var testKloudHook = nop

func nop(*kloud.Client) {}

func AuthLogin(c *cli.Context, log logging.Logger, _ string) (int, error) {
	kodingURL, err := url.Parse(c.String("baseurl"))
	if err != nil {
		return 1, fmt.Errorf("%q is not a valid URL value: %s\n", c.String("koding"), err)
	}

	k, ok := configstore.List()[config.ID(kodingURL.String())]
	if !ok {
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

	testKloudHook(kloudClient)

	authClient := &auth.Client{
		Kloud: kloudClient,
		Kontrol: &kontrol.Client{
			Kloud: kloudClient,
		},
	}

	teamClient := &team.Client{
		Kloud: kloudClient,
	}

	// If we already own a valid kite.key, it means we were already
	// authenticated and we just call kloud using kite.key authentication.
	err = kloudClient.Transport.(stack.Validator).Valid()

	log.Debug("auth: transport test: %s", err)

	opts := &auth.LoginOptions{
		Team:  c.String("team"),
		Token: c.String("token"),
	}

	if err != nil && opts.Token == "" {
		opts.Username, err = helper.Ask("Username [%s]: ", config.CurrentUser.Username)
		if err != nil {
			return 1, err
		}

		if opts.Username == "" {
			opts.Username = config.CurrentUser.Username
		}

		for {
			opts.Password, err = helper.AskSecret("Password [***]: ")
			if err != nil {
				return 1, err
			}
			if opts.Password != "" {
				break
			}
		}
	}

	fmt.Fprintln(os.Stderr, "Logging to", kodingURL, "...")

	resp, err := authClient.Login(opts)
	if err != nil {
		return 1, fmt.Errorf("error logging into your Koding account: %v", err)
	}

	if resp.KiteKey != "" {
		k.KiteKey = resp.KiteKey
		k.Endpoints = resp.Metadata.Endpoints

		if err := configstore.Use(k); err != nil {
			return 1, err
		}
	}

	teamClient.Use(&team.Team{Name: resp.GroupName})

	if c.Bool("json") {
		enc := json.NewEncoder(os.Stdout)
		enc.SetIndent("", "\t")
		enc.Encode(resp)
	} else {
		fmt.Fprintln(os.Stdout, "Successfully logged in to the following team:", resp.GroupName)
	}

	return 0, nil
}
