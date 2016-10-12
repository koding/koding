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

type Credentials struct {
	Defaults   map[string]string
	ByProvider map[string][]*stack.CredentialItem
	ByIdent    map[string]*stack.CredentialItem
}

func (c *Credentials) Len() int {
	return len(c.ByIdent)
}

func (c *Credentials) Providers() []string {
	providers := make([]string, 0, len(c.ByProvider))

	for provider := range c.ByProvider {
		providers = append(providers, provider)
	}

	sort.Strings(providers)

	return providers
}

func (c *Credentials) String() string {
	var buf bytes.Buffer

	switch providers := c.Providers(); len(providers) {
	case 1:
		if n := len(c.ByProvider[providers[0]]); n > 1 {
			fmt.Fprintf(&buf, "%d %s credentials", n, providers[0])
		} else {
			fmt.Fprintf(&buf, "%d %s credential", n, providers[0])
		}
	case 2:
		if n, m := len(c.ByProvider[providers[0]]), len(c.ByProvider[providers[1]]); n > 1 || m > 1 {
			fmt.Fprintf(&buf, "%d %s and %d %s credentials", n, providers[0], m, providers[1])
		} else {
			fmt.Fprintf(&buf, "%d %s and %d %s credential", n, providers[0], m, providers[1])
		}
	default:
		n := len(c.ByProvider[providers[0]])
		fmt.Fprintf(&buf, "%d %s", n, providers[0])

		for _, provider := range providers[1 : len(providers)-1] {
			m := len(c.ByProvider[provider])
			n = max(n, m)

			fmt.Fprintf(&buf, ", %d %s", m, provider)
		}

		last := providers[len(providers)-1]
		m := len(c.ByProvider[last])

		if max(n, m) > 1 {
			fmt.Fprintf(&buf, "and %d %s credentials.", m, last)
		} else {
			fmt.Fprintf(&buf, "and %d %s credential.", m, last)
		}
	}

	return buf.String()
}

func (c *Credentials) Import(resp *stack.CredentialListResponse) {
	c.ByProvider = make(map[string][]*stack.CredentialItem)
	c.ByIdent = make(map[string]*stack.CredentialItem)

	for provider, creds := range resp.Credentials {
		for i := range creds {
			c.ByProvider[provider] = append(c.ByProvider[provider], &creds[i])
			c.ByIdent[creds[i].Identifier] = &creds[i]
		}
	}

	for provider, ident := range c.Defaults {
		if _, ok := c.ByIdent[ident]; !ok {
			delete(c.Defaults, provider)
		}
	}
}

func (c *Credentials) Default() map[string]*stack.CredentialItem {
	m := make(map[string]*stack.CredentialItem)

	for _, ident := range c.Defaults {
		if cred, ok := c.ByIdent[ident]; ok {
			m[cred.Provider] = cred
		}
	}

	return m
}

func CredentialImport(c *cli.Context, log logging.Logger, _ string) (int, error) {
	debug = c.Bool("debug")

	var credentials Credentials

	if err := Cache().GetValue("credentials", &credentials); err != nil && err != storage.ErrKeyNotFound {
		return 1, err
	}

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

	credentials.Import(&resp)

	if err := Cache().SetValue("credentials", &credentials); err != nil {
		return 1, err
	}

	if credentials.Len() == 0 {
		fmt.Fprintln(os.Stderr, "You have no credentials attached to your Koding account.")
		return 1, nil
	}

	fmt.Printf("Imported %s.\n", &credentials)

	return 0, nil
}

func CredentialList(c *cli.Context, log logging.Logger, _ string) (int, error) {
	debug = c.Bool("debug")

	provider := c.String("provider")
	team := c.String("team")

	var credentials Credentials

	if err := Cache().GetValue("credentials", &credentials); err != nil && err != storage.ErrKeyNotFound {
		return 1, err
	}

	if credentials.Len() == 0 {
		fmt.Fprintln(os.Stderr, `You did not import any credentials yet. Please run "kd credential import".`)
		return 1, nil
	}

	if provider != "" {
		for p := range credentials.ByProvider {
			if p != provider {
				delete(credentials.ByProvider, provider)
			}
		}
	}

	if team != "" {
		for provider, creds := range credentials.ByProvider {
			var filtered []*stack.CredentialItem

			for _, cred := range creds {
				if cred.Team != "" && cred.Team != team {
					continue
				}

				filtered = append(filtered, cred)
			}

			if len(filtered) != 0 {
				credentials.ByProvider[provider] = filtered
			} else {
				delete(credentials.ByProvider, provider)
			}
		}
	}

	if credentials.Len() == 0 {
		fmt.Fprintln(os.Stderr, "You have no matching credentials attached to your Koding account.")
		return 0, nil
	}

	enc := json.NewEncoder(os.Stdout)
	enc.SetIndent("", "\t")

	if err := enc.Encode(credentials.ByProvider); err != nil {
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
	var credentials Credentials

	if err := Cache().GetValue("credentials", &credentials); err != nil && err != storage.ErrKeyNotFound {
		return 1, err
	}

	if credentials.Len() == 0 {
		fmt.Fprintln(os.Stderr, `You did not import any credentials yet. Please run "kd credential import".`)
		return 1, nil
	}

	ident := c.Args().Get(0)

	if ident == "" {
		m := credentials.Default()

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

	cred, ok := credentials.ByIdent[ident]
	if !ok {
		fmt.Fprintf(os.Stderr, `Credential identifier not found. Please try "kd credential import".`)
		return 1, nil
	}

	if credentials.Defaults == nil {
		credentials.Defaults = make(map[string]string)
	}

	credentials.Defaults[cred.Provider] = cred.Identifier

	if err := Cache().SetValue("credentials", &credentials); err != nil {
		return 1, err
	}

	fmt.Printf("Set %s as a default credential for %q stacks.\n", cred.Identifier, cred.Provider)

	return 0, nil
}
