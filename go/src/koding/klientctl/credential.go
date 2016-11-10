package main

import (
	"errors"
	"fmt"
	"io/ioutil"
	"os"

	"koding/kites/kloud/utils/object"
	"koding/klientctl/kloud/credential"

	"github.com/codegangsta/cli"
	"github.com/koding/logging"
)

func CredentialList(c *cli.Context, log logging.Logger, _ string) (int, error) {
	provider := c.String("provider")
	team := c.String("team")

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
		object.JSONPrinter.Print(creds)
		return 0, nil
	}

	object.TabPrinter.Print(creds.ToSlice())

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

	fmt.Fprintln(os.Stderr, "Creating credential... ")

	opts := &credential.CreateOptions{
		Provider: c.String("provider"),
		Team:     c.String("team"),
		Title:    c.String("title"),
		Data:     p,
	}

	cred, err := credential.Create(opts)
	if err != nil {
		fmt.Fprintln(os.Stderr, "Error creating credential:", err)
		return 1, err
	}

	fmt.Fprintf(os.Stderr, "Created %q credential with %s identifier.\n", cred.Title, cred.Identifier)

	return 0, nil
}
