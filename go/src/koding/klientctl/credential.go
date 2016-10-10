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

	"github.com/codegangsta/cli"
	"github.com/koding/logging"
)

// TODO(rjeczalik):
//
//   - improve "credential add" to ask user interactively about
//     the credentials (build the question dynamically basing
//     on kloud's credential.describe)
//   - improve --json handling in "credential list"
//

type DefaultCredentials struct {
	Global map[string]string
}

func CredentialImport(c *cli.Context, log logging.Logger, _ string) (int, error) {
	debug = c.Bool("debug")

	kloud, err := Kloud()
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

	if err := Cache().SetValue("credentials", &resp); err != nil {
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
		if n := len(creds[keys[0]]); n > 1 {
			fmt.Fprintf(&buf, "Imported %d %s credentials.", n, keys[0])
		} else {
			fmt.Fprintf(&buf, "Imported %d %s credential.", n, keys[0])
		}
	case 2:
		if n, m := len(creds[keys[0]]), len(creds[keys[1]]); n > 1 || m > 1 {
			fmt.Fprintf(&buf, "Imported %d %s and %d %s credentials.", n, keys[0], m, keys[1])
		} else {
			fmt.Fprintf(&buf, "Imported %d %s and %d %s credential.", n, keys[0], m, keys[1])
		}
	default:
		n := len(creds[keys[0]])
		fmt.Fprintf(&buf, "Imported %d %s", n, keys[0])

		for _, key := range keys[1 : len(keys)-1] {
			fmt.Fprintf(&buf, ", %d %s", len(creds[key]), key)
			n = max(n, len(creds[key]))
		}

		last := keys[len(keys)-1]
		n = max(n, len(creds[last]))

		if n > 1 {
			fmt.Fprintf(&buf, "and %d %s credentials.", len(creds[last]), last)
		} else {
			fmt.Fprintf(&buf, "and %d %s credential.", len(creds[last]), last)
		}
	}

	fmt.Println(buf.String())

	return 0, nil
}

func CredentialList(c *cli.Context, log logging.Logger, _ string) (int, error) {
	debug = c.Bool("debug")

	provider := c.String("provider")
	team := c.String("team")

	var resp stack.CredentialListResponse

	if err := Cache().GetValue("credentials", &resp); err != nil && err != storage.ErrKeyNotFound {
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
	debug = c.Bool("debug")

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

	kloud, err := Kloud()
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

	if err := Cache().GetValue("credentials", &creds); err != nil && err != storage.ErrKeyNotFound {
		return 1, err
	}

	if creds.Credentials == nil {
		creds.Credentials = make(map[string][]stack.CredentialItem)
	}

	creds.Credentials[req.Provider] = append(creds.Credentials[req.Provider], cred)

	if err := Cache().SetValue("credentials", &creds); err != nil {
		return 1, err
	}

	return 0, nil
}

func CredentialUse(c *cli.Context, log logging.Logger, _ string) (int, error) {
	var creds stack.CredentialListResponse

	if err := Cache().GetValue("credentials", &creds); err != nil && err != storage.ErrKeyNotFound {
		return 1, err
	}

	if len(creds.Credentials) == 0 {
		fmt.Fprintln(os.Stderr, `You did not import any credentials yet. Please run "kd credential import".`)
		return 1, nil
	}

	defaults := &DefaultCredentials{
		Global: make(map[string]string),
	}

	if err := Cache().GetValue("defaultCredentials", defaults); err != nil && err != storage.ErrKeyNotFound {
		return 1, err
	}

	if len(c.Args()) == 0 || c.Args().Get(0) == "" {
		m := make(map[string]stack.CredentialItem, len(defaults.Global))

		for p, ident := range defaults.Global {
			for _, cred := range creds.Credentials[p] {
				if cred.Identifier == ident {
					m[p] = cred
					break
				}
			}
		}

		if len(m) == 0 {
			fmt.Fprintln(os.Stderr, "You have no default credential set.")
			return 1, nil
		}

		enc := json.NewEncoder(os.Stdout)
		enc.SetIndent("", "\t")

		if err := enc.Encode(m); err != nil {
			return 1, err
		}

		return 0, nil
	}

	ident := c.Args().Get(0)
	provider := ""

lookup:
	for p, creds := range creds.Credentials {
		for _, cred := range creds {
			if cred.Identifier == ident {
				provider = p
				break lookup
			}
		}
	}

	if provider == "" {
		fmt.Fprintf(os.Stderr, `Credential identifier not found. Please try "kd credential import".`)
		return 1, nil
	}

	defaults.Global[provider] = ident

	if err := Cache().SetValue("defaultCredentials", defaults); err != nil {
		return 1, err
	}

	fmt.Printf("Set %s as a default credential for %q stacks.\n", ident, provider)

	return 0, nil
}
