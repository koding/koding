package main

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io/ioutil"
	"os"
	"sort"
	"time"

	"koding/kites/kloud/stack"
	"koding/klient/storage"
	"koding/klientctl/kloud"

	"github.com/codegangsta/cli"
	"github.com/koding/logging"
)

// TODO(rjeczalik):
//
//   - improve "credential add" to ask user interactively about
//     the credentials (build the question dynamically basing
//     on kloud's credential.describe)
//   - improve --json handling in "credential list"
//   - add "credential use" for setting default credentials
//     for "kd stack create" command
//

func CredentialImport(c *cli.Context, log logging.Logger, _ string) (int, error) {
	kloud, err := kloud.Kloud(log)
	if err != nil {
		fmt.Fprintln(os.Stderr, "Error communicating with Koding:", err)
		return 1, err
	}

	req := &stack.CredentialListRequest{
		Team:     c.String("team"),
		Provider: c.String("provider"),
	}

	r, err := kloud.TellWithTimeout("credential.list", 10*time.Second, req)
	if err != nil {
		fmt.Fprintln(os.Stderr, "Error communicating with Koding:", err)
		return 1, err
	}

	var resp stack.CredentialListResponse

	if err := r.Unmarshal(&resp); err != nil {
		return 1, err
	}

	if err := kloud.Cache().SetValue("credentials", &resp); err != nil {
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

		fmt.Fprintf(&buf, " and %d %s credentials.", len(creds[last]), last)
	}

	fmt.Println(buf.String())

	return 0, nil
}

func CredentialList(c *cli.Context, log logging.Logger, _ string) (int, error) {
	provider := c.String("provider")
	team := c.String("team")

	var resp stack.CredentialListResponse

	if err := kloud.Cache().GetValue("credentials", &resp); err != nil && err != storage.ErrKeyNotFound {
		return 1, err
	}

	if len(resp.Credentials) == 0 {
		fmt.Fprintln(os.Stderr, `You did not import any credentials yet. Please run "kd credential import".`)
		return 1, nil
	}

	if provider != "" {
		for key := range resp.Credentials {
			if key != provider {
				delete(resp.Credentials, key)
			}
		}
	}

	if team != "" {
		for key, creds := range resp.Credentials {
			var filtered []stack.CredentialItem

			for _, cred := range creds {
				if cred.Team != "" && cred.Team != team {
					continue
				}

				filtered = append(filtered, cred)
			}

			if len(filtered) != 0 {
				resp.Credentials[key] = filtered
			} else {
				delete(resp.Credentials, key)
			}
		}
	}

	if len(resp.Credentials) == 0 {
		fmt.Fprintln(os.Stderr, "You have no matching credentials attached to your Koding account.")
		return 0, nil
	}

	enc := json.NewEncoder(os.Stdout)
	enc.SetIndent("", "\t")

	if err := enc.Encode(resp.Credentials); err != nil {
		return 1, err
	}

	return 0, nil
}

func CredentialCreate(c *cli.Context, log logging.Logger, _ string) (int, error) {
	var p []byte
	var err error

	switch file := c.String("file"); file {
	case "":
		// TODO(rjeczalik): remove once interactive mode is implemented
		fmt.Fprintln(os.Stderr, "No credential file was provided.")
		return 1, errors.New("no credential file was provided")
	case "-":
		p, err = ioutil.ReadAll(os.Stdin)
	default:
		p, err = ioutil.ReadFile(file)
	}

	if err != nil {
		fmt.Fprintln(os.Stderr, "Error reading credential file: ", err)
		return 1, err
	}

	kloud, err := kloud.Kloud(log)
	if err != nil {
		fmt.Fprintln(os.Stderr, "Error communicating with Koding:", err)
		return 1, err
	}

	req := &stack.CredentialAddRequest{
		Provider: c.String("provider"),
		Team:     c.String("team"),
		Title:    c.String("title"),
		Data:     json.RawMessage(p),
	}

	fmt.Println("Creating credential... ")

	r, err := kloud.TellWithTimeout("credential.add", 10*time.Second, req)
	if err != nil {
		fmt.Fprintln(os.Stderr, "Error communicating with Koding:", err)
		return 1, err
	}

	var resp stack.CredentialAddResponse

	if err := r.Unmarshal(&resp); err != nil {
		return 1, err
	}

	cred := stack.CredentialItem{
		Identifier: resp.Identifier,
		Title:      resp.Title,
	}

	fmt.Printf("Created %q credential with %s identifier.\n", cred.Title, cred.Identifier)

	var creds stack.CredentialListResponse

	if err := kloud.Cache().GetValue("credentials", &creds); err != nil && err != storage.ErrKeyNotFound {
		return 1, err
	}

	if creds.Credentials == nil {
		creds.Credentials = make(map[string][]stack.CredentialItem)
	}

	creds.Credentials[req.Provider] = append(creds.Credentials[req.Provider], cred)

	if err := kloud.Cache().SetValue("credentials", &creds); err != nil {
		return 1, err
	}

	return 0, nil
}
