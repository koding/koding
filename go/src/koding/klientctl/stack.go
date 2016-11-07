package main

import (
	"errors"
	"fmt"
	"io/ioutil"
	"os"
	"time"

	"koding/kites/kloud/stack"
	"koding/klient/storage"
	"koding/klientctl/lazy"

	"github.com/codegangsta/cli"
	"github.com/koding/logging"
)

func StackCreate(c *cli.Context, log logging.Logger, _ string) (int, error) {
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

	kloud, err := lazy.Kloud(log)
	if err != nil {
		fmt.Fprintln(os.Stderr, "Error communicating with Koding:", err)
		return 1, err
	}

	req := &stack.ImportRequest{
		Template:    p,
		Credentials: make(map[string][]string),
		Team:        c.String("team"),
		Title:       c.String("title"),
		Provider:    c.String("provider"),
	}

	var creds stack.CredentialListResponse

	if err := lazy.Cache().GetValue("credentials", &creds); err != nil && err != storage.ErrKeyNotFound {
		return 1, err
	}

	for _, identifier := range c.StringSlice("credential") {
		if provider := creds.Provider(identifier); provider != "" {
			req.Credentials[provider] = append(req.Credentials[provider], identifier)
		}
	}

	fmt.Println("Creating stack... ")

	r, err := kloud.TellWithTimeout("import", 2*time.Minute, req)
	if err != nil {
		fmt.Fprintln(os.Stderr, "Error communicating with Koding:", err)
		return 1, err
	}

	var resp stack.ImportResponse

	if err := r.Unmarshal(&resp); err != nil {
		return 1, err
	}

	fmt.Printf("Creatad %q stack with %s ID.\n", resp.Title, resp.StackID)

	return 0, nil
}
