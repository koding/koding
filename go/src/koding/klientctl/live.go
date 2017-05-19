package main

import (
	"errors"
	"fmt"
	"os"
	"strconv"
	"strings"

	kstack "koding/kites/kloud/stack"
	"koding/klientctl/config"
	"koding/klientctl/endpoint/credential"
	"koding/klientctl/endpoint/kloud"
	"koding/klientctl/endpoint/stack"
	"koding/klientctl/endpoint/team"
	"koding/klientctl/helper"

	"github.com/koding/logging"
	cli "gopkg.in/urfave/cli.v1"
)

// TODO(rjeczalik):
//
//   - add application mixin (buildstep)
//   - add package for building with mixins
//   - change flow to include:
//      - application mixin in templateInit (port / ssh key?)
//      - waiting for _KD_DONE_ (add Stack.Wait?)
//      - uploading files
//      - building / waiting
//      - mounting remote
//      - printing remote URL

func Live(c *cli.Context, log logging.Logger, _ string) (int, error) {
	if err := isLocked(); err != nil {
		return 1, err
	}

	if _, err := os.Stat(config.Konfig.Template.File); os.IsNotExist(err) {
		fmt.Printf("Initializing with new %s template file...\n\n", config.Konfig.Template.File)

		if err := templateInit(config.Konfig.Template.File, false, ""); err != nil {
			return 1, err
		}
	}

	p, err := readTemplate(config.Konfig.Template.File)
	if err != nil {
		return 1, err
	}

	provider, err := kstack.ReadProvider(p)
	if err != nil {
		return 1, errors.New("failed to read cloud provider: " + err.Error())
	}

	ident := credential.Used()[provider]

	switch {
	case ident == "":
		opts := &credential.ListOptions{
			Provider: provider,
			Team:     team.Used().Name,
		}
		c, err := credential.List(opts)
		if err != nil {
			log.Debug("credential.List failure: %s", err)
			break
		}

		creds, ok := c[provider]
		if !ok || len(creds) == 0 {
			fmt.Printf("Creating new credential for %q provider...\n\n", strings.Title(provider))

			opts := &credential.CreateOptions{
				Provider: provider,
				Team:     team.Used().Name,
			}

			if err := credentialCreate("", opts, false); err != nil {
				return 1, err
			}

			break
		}

		for i, cred := range creds {
			fmt.Printf("[%d] %s\n", i+1, cred.Title)
		}

		s, err := helper.Ask("\nChoose credential to use [1]: ")
		if err != nil {
			return 1, err
		}

		if s == "" {
			s = "1"
		}

		n, err := strconv.Atoi(s)
		if err != nil {
			return 1, fmt.Errorf("unrecognized credential chosen: %s", s)
		}

		if n--; n < 0 || n >= len(creds) {
			return 1, fmt.Errorf("invalid credential chosen: %d", n)
		}

		ident = creds[n].Identifier
		credential.Use(ident)
	}

	if ident == "" {
		ident = credential.Used()[provider]
	}

	fmt.Printf("Creating new stack...\n\n")
	defTitle := strings.Title(fmt.Sprintf("%s %s Stack", kstack.Pokemon(), provider))

	title, err := helper.Ask("Stack name [%s]: ", defTitle)
	if err != nil {
		return 1, err
	}

	if title == "" {
		title = defTitle
	}

	opts := &stack.CreateOptions{
		Team:        team.Used().Name,
		Title:       title,
		Credentials: []string{ident},
		Template:    p,
	}

	resp, err := stack.Create(opts)
	if err != nil {
		return 1, err
	}

	fmt.Fprintf(os.Stderr, "\nCreatad %q stack with %s ID.\nWaiting for the stack to finish building...\n\n", resp.Title, resp.StackID)

	for e := range kloud.Wait(resp.EventID) {
		if e.Error != nil {
			return 1, fmt.Errorf("\nBuilding %q stack failed:\n%s\n", resp.Title, e.Error)
		}

		fmt.Printf("[%d%%] %s\n", e.Event.Percentage, e.Event.Message)
	}

	if err := writelock(resp.StackID, resp.Title); err != nil {
		return 1, err
	}

	return 0, nil
}
