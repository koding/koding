package main

import (
	"encoding/json"
	"fmt"
	"net/url"
	"os"

	"koding/klientctl/ctlcli"
	"koding/klientctl/endpoint/auth"
	"koding/klientctl/endpoint/kloud"

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

	f, err := auth.NewFacade(&auth.FacadeOptions{
		Base: kodingURL,
		Log:  log,
	})

	if err != nil {
		return 1, err
	}

	ctlcli.CloseOnExit(f)
	testKloudHook(f.Kloud)

	fmt.Fprintln(os.Stderr, "Logging to", kodingURL, "...")

	opts := &auth.LoginOptions{
		Team:  c.String("team"),
		Token: c.String("token"),
		Force: c.Bool("force"),
	}

	resp, err := f.Login(opts)
	if err != nil {
		return 1, fmt.Errorf("error logging into your Koding account: %v", err)
	}

	if c.Bool("json") {
		enc := json.NewEncoder(os.Stdout)
		enc.SetIndent("", "\t")
		enc.Encode(resp)

		return 0, nil
	}

	if resp.GroupName != "" {
		fmt.Println("Successfully logged in to the following team:", resp.GroupName)
	} else {
		fmt.Printf("Successfully authenticated to Koding.\n\nPlease run \"kd auth login " +
			"[--team myteam]\" in order to login to your team.\n")
	}

	fmt.Printf("\nPlease run \"sudo kd restart\" for the new configuration to take effect.\n")

	return 0, nil
}

func AuthShow(c *cli.Context, _ logging.Logger, _ string) (int, error) {
	return 0, nil
}
