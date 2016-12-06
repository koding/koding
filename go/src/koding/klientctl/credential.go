package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"strconv"
	"text/tabwriter"
	"time"

	"koding/kites/config"
	"koding/kites/kloud/stack"
	"koding/klientctl/endpoint/credential"
	"koding/klientctl/helper"

	"github.com/codegangsta/cli"
	"github.com/koding/logging"
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

func AskCredentialCreate(c *cli.Context) (*credential.CreateOptions, error) {
	descs, err := credential.Describe()
	if err != nil {
		return nil, err
	}

	opts := &credential.CreateOptions{
		Provider: c.String("provider"),
		Team:     c.String("team"),
		Title:    c.String("title"),
	}

	if opts.Provider == "" {
		opts.Provider, err = helper.Ask("Provider type []: ")
		if err != nil {
			return nil, err
		}
	}

	if opts.Title == "" {
		opts.Title = config.CurrentUser.Username + " " + time.Now().Format(time.ANSIC)
		opts.Title, err = helper.Ask("Title [%s]: ", opts.Title)
		if err != nil {
			return nil, err
		}
	}

	desc, ok := descs[opts.Provider]
	if !ok {
		return nil, fmt.Errorf("provider %q does not exist", opts.Provider)
	}

	creds := make(map[string]interface{}, len(desc.Credential))

	// TODO(rjeczalik): Add field.OmitEmpty so we validate required
	// fields client-side.
	//
	// TODO(rjeczalik): Refactor part which validates credential
	// input on kloud/provider side to a separate library
	// and use it here.
	for _, field := range desc.Credential {
		var value string

		if field.Secret {
			value, err = helper.AskSecret("%s [***]: ", field.Label)
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

			value, err = helper.Ask("%s [%s]: ", field.Label, defaultValue)

			if value == "" {
				value = defaultValue
			}
		}

		if err != nil {
			return nil, err
		}

		switch field.Type {
		case "integer":
			n, err := strconv.Atoi(value)
			if err != nil {
				return nil, fmt.Errorf("invalid integer for %q field: %s", field.Label, err)
			}

			creds[field.Name] = n
		case "duration":
			d, err := time.ParseDuration(value)
			if err != nil {
				return nil, fmt.Errorf("invalid time duration for %q field: %s", field.Label, err)
			}

			creds[field.Name] = d
		case "enum":
			if !field.Values.Contains(value) {
				return nil, fmt.Errorf("invalid %q enumeration value for %q field - valid values are: %v", value, field.Label, field.Values.Values())
			}

			creds[field.Name] = value
		default:
			creds[field.Name] = value
		}
	}

	// TODO(rjeczalik): remove when support for generic team is implemented
	if opts.Team == "" {
		opts.Team, err = helper.Ask("Team name []: ")
		if err != nil {
			return nil, err
		}
	}

	p, err := json.Marshal(creds)
	if err != nil {
		return nil, err
	}

	opts.Data = p

	return opts, nil
}

func CredentialCreate(c *cli.Context, log logging.Logger, _ string) (int, error) {
	var p []byte
	var err error
	var opts *credential.CreateOptions

	switch file := c.String("file"); file {
	case "":
		opts, err = AskCredentialCreate(c)
		if err != nil {
			fmt.Fprintln(os.Stderr, "Error building credential data:", err)
			return 1, err
		}
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

	if opts == nil {
		opts = &credential.CreateOptions{
			Provider: c.String("provider"),
			Team:     c.String("team"),
			Title:    c.String("title"),
			Data:     p,
		}
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

func CredentialDescribe(c *cli.Context, log logging.Logger, _ string) (int, error) {
	descs, err := credential.Describe()
	if err != nil {
		fmt.Fprintln(os.Stderr, "Error requesting credential description:", err)
		return 1, err
	}

	if p := c.String("provider"); p != "" {
		desc, ok := descs[p]
		if !ok {
			fmt.Fprintf(os.Stderr, "No description found for %q provider.\n", p)
			return 1, err
		}

		descs = stack.Descriptions{p: desc}
	}

	if c.Bool("json") {
		p, err := json.MarshalIndent(descs.Slice(), "", "\t")
		if err != nil {
			return 1, err
		}

		fmt.Printf("%s\n", p)

		return 0, nil
	}

	printDescs(descs.Slice())

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

func printDescs(descs []*stack.Description) {
	w := tabwriter.NewWriter(os.Stdout, 2, 0, 2, ' ', 0)
	defer w.Flush()

	fmt.Fprintln(w, "PROVIDER\tATTRIBUTE\tTYPE\tSECRET")

	for _, desc := range descs {
		for _, field := range desc.Credential {
			fmt.Fprintf(w, "%s\t%s\t%s\t%t\n", desc.Provider, field.Name, field.Type, field.Secret)
		}
	}
}
