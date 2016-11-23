package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"strconv"
	"strings"
	"text/tabwriter"
	"time"

	"koding/kites/kloud/stack"
	"koding/klientctl/kloud/credential"

	"github.com/codegangsta/cli"
	"github.com/koding/logging"
	"golang.org/x/crypto/ssh/terminal"
)

func CredentialList(c *cli.Context, log logging.Logger, _ string) (int, error) {
	opts := &credential.ListOptions{
		Provider: c.String("provider"),
		Team:     c.String("team"),
	}

	creds, err := credential.List(opts)
	if err != nil {
		return 0, err
	}

	if len(creds) == 0 {
		fmt.Fprintln(os.Stderr, "You have no matching credentials attached to your Koding account.")
		return 0, nil
	}

	if c.Bool("json") {
		p, err := json.MarshalIndent(creds, "", "\t")
		if err != nil {
			return 1, err
		}

		fmt.Printf("%s\n", p)

		return 0, nil
	}

	printCreds(creds.ToSlice())

	return 0, nil
}

func ask(format string, args ...interface{}) (string, error) {
	fmt.Printf(format, args...)
	s, err := bufio.NewReader(os.Stdin).ReadString('\n')
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(s), nil
}

func askSecret(format string, args ...interface{}) (string, error) {
	fmt.Printf(format, args...)
	p, err := terminal.ReadPassword(int(os.Stdin.Fd()))
	fmt.Println()
	if err != nil {
		return "", err
	}
	return string(p), nil
}

func AskCredential(c *cli.Context) (provider string, creds map[string]interface{}, err error) {
	descs, err := credential.Describe()
	if err != nil {
		return "", nil, err
	}

	provider = c.String("provider")

	if provider == "" {
		s, err := ask("Provider type []: ")
		if err != nil {
			return "", nil, err
		}

		provider = s
	}

	desc, ok := descs[provider]
	if !ok {
		return "", nil, fmt.Errorf("provider %q does not exist", provider)
	}

	creds = make(map[string]interface{}, len(desc.Credential))

	// TODO(rjeczalik): Add field.OmitEmpty so we validate required
	// fields client-side.
	//
	// TODO(rjeczalik): Refactor part which validates credential
	// input on kloud/provider side to a separate library
	// and use it here.
	for _, field := range desc.Credential {
		var value string

		if field.Secret {
			value, err = askSecret("%s [***]: ", field.Label)
		} else {
			var defaultValue string

			switch {
			case len(field.Values) > 0:
				if s, ok := field.Values[0].Value.(string); ok {
					defaultValue = s
				}
			case field.Type == "duration":
				defaultValue = "0s"
			case field.Type == "integer":
				defaultValue = "0"
			}

			value, err = ask("%s [%s]: ", field.Label, defaultValue)

			if value == "" {
				value = defaultValue
			}
		}

		if err != nil {
			return "", nil, err
		}

		switch field.Type {
		case "integer":
			n, err := strconv.Atoi(value)
			if err != nil {
				return "", nil, fmt.Errorf("invalid integer for %q field: %s", field.Label, err)
			}

			creds[field.Name] = n
		case "duration":
			d, err := time.ParseDuration(value)
			if err != nil {
				return "", nil, fmt.Errorf("invalid time duration for %q field: %s", field.Label, err)
			}

			creds[field.Name] = d
		default:
			creds[field.Name] = value
		}
	}

	return provider, creds, nil
}

func CredentialCreate(c *cli.Context, log logging.Logger, _ string) (int, error) {
	var p []byte
	var err error
	var provider = c.String("provider")

	switch file := c.String("file"); file {
	case "":
		s, creds, err := AskCredential(c)
		if err != nil {
			fmt.Fprintln(os.Stderr, "Error building credential data:", err)
			return 1, err
		}

		p, err = json.Marshal(creds)
		provider = s
	case "-":
		p, err = ioutil.ReadAll(os.Stdin)
	default:
		p, err = ioutil.ReadFile(file)
	}

	if err != nil {
		fmt.Fprintln(os.Stderr, "Error reading credential file:", err)
		return 1, err
	}

	fmt.Fprintln(os.Stderr, "Creating credential... ")

	opts := &credential.CreateOptions{
		Provider: provider,
		Team:     c.String("team"),
		Title:    c.String("title"),
		Data:     p,
	}

	cred, err := credential.Create(opts)
	if err != nil {
		fmt.Fprintln(os.Stderr, "Error creating credential:", err)
		return 1, err
	}

	if c.Bool("json") {
		p, err := json.MarshalIndent(cred, "", "\t")
		if err != nil {
			return 1, err
		}

		fmt.Printf("%s\n", p)

		return 0, nil
	}

	fmt.Fprintf(os.Stderr, "Created %q credential with %s identifier.\n", cred.Title, cred.Identifier)

	return 0, nil
}

func printCreds(creds []stack.CredentialItem) {
	w := tabwriter.NewWriter(os.Stdout, 2, 0, 2, ' ', 0)
	defer w.Flush()

	fmt.Fprintln(w, "ID\tTITLE\tTEAM\tPROVIDER")

	for _, cred := range creds {
		fmt.Fprintf(w, "%s\t%s\t%s\t%s\n", cred.Identifier, cred.Title, cred.Team, cred.Provider)
	}
}
