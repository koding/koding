package main

import (
	"bytes"
	"fmt"
	"sort"
	"time"

	"koding/kites/kloud/stack"

	"github.com/codegangsta/cli"
	"github.com/koding/logging"
)

func CredentialImport(c *cli.Context, log logging.Logger, _ string) (int, error) {
	kloud, err := Kloud()
	if err != nil {
		return 1, err
	}

	req := &stack.CredentialListRequest{
		Team:     c.String("team"),
		Provider: c.String("provider"),
	}

	r, err := kloud.TellWithTimeout("credential.list", 10*time.Second, req)
	if err != nil {
		return 1, err
	}

	var resp stack.CredentialListResponse

	if err := r.Unmarshal(&resp); err != nil {
		return 1, err
	}

	if err := Cache().SetValue("credential", &resp); err != nil {
		return 1, err
	}

	creds := resp.Credentials
	keys := make([]string, 0, len(creds))

	for key := range creds {
		keys = append(keys, key)
	}

	sort.Strings(keys)

	var buf bytes.Buffer

	switch len(keys) {
	case 0:
		fmt.Fprintf(&buf, "You have no credentials attached to your Koding account.")
	case 1:
		fmt.Fprintf(&buf, "Imported %d %s credential.", len(creds[keys[0]]), keys[0])
	case 2:
		fmt.Fprintf(&buf, "Imported %d %s and %d %s credentials.", len(creds[keys[0]]), keys[0], len(creds[keys[1]]), keys[1])
	default:
		fmt.Fprintf(&buf, "Imported %d %s", len(creds[keys[0]]), keys[0])

		for _, key := range keys[1 : len(keys)-1] {
			fmt.Fprintf(&buf, ", %d %s", len(creds[key]), key)
		}

		last := keys[len(keys)-1]

		fmt.Fprintf(&buf, "and %d %s credentials.", len(creds[last]), last)
	}

	fmt.Println(buf.String())

	return 0, nil
}

func CredentialList(c *cli.Context, log logging.Logger, _ string) (int, error) {
	return 0, nil
}

func CredentialCreate(c *cli.Context, log logging.Logger, _ string) (int, error) {
	return 0, nil
}
