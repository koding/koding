package main

import (
	"encoding/json"
	"fmt"
	"net/url"
	"os"

	"koding/klientctl/endpoint/auth"
	"koding/klientctl/endpoint/kloud"
	"koding/klientctl/endpoint/kontrol"
	"koding/klientctl/endpoint/team"

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

	f, err := auth.NewFacade(&auth.FacadeOpts{
		Base: kodingURL,
		Log:  log,
	})

	if err != nil {
		return 1, err
	}

	testKloudHook(f.Kloud)

	fmt.Fprintln(os.Stderr, "Logging to", kodingURL, "...")

	opts := &auth.LoginOptions{
		Team:  c.String("team"),
		Token: c.String("token"),
	}

	if err != nil && opts.Token == "" {
		if err = opts.AskUserPass(); err != nil {
			return 1, err
		}
	}

	fmt.Fprintln(os.Stderr, "Logging to", kodingURL, "...")

	resp, err := authClient.Login(opts)
	if err != nil {
		return 1, fmt.Errorf("error logging into your Koding account: %v", err)
	}

	if c.Bool("json") {
		enc := json.NewEncoder(os.Stdout)
		enc.SetIndent("", "\t")
		enc.Encode(resp)
	} else if resp.GroupName != "" {
		fmt.Fprintln(os.Stdout, "Successfully logged in to the following team:", resp.GroupName)
	} else {
		fmt.Fprintf(os.Stdout, "Successfully authenticated to Koding.\n\nPlease run \"kd auth login "+
			"[--team myteam]\" in order to login to your team.\n")
	}

	return 0, nil
}
