package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"io/ioutil"
	"os"
	"strconv"
	"strings"

	yaml "gopkg.in/yaml.v2"

	kstack "koding/kites/kloud/stack"
	"koding/kites/kloud/utils/object"
	"koding/klientctl/endpoint/credential"
	"koding/klientctl/endpoint/kloud"
	"koding/klientctl/endpoint/stack"
	"koding/klientctl/endpoint/team"
	"koding/klientctl/helper"

	"github.com/codegangsta/cli"
	"github.com/koding/logging"
)

func Init(c *cli.Context, log logging.Logger, _ string) (int, error) {
	if err := trylock(); err != nil {
		return 1, err
	}

	switch _, err := os.Stat("kd.yaml"); {
	case os.IsNotExist(err):
		fmt.Printf("Initializing with new kd.yaml template file...\n\n")

		if err := templateInit("kd.yaml"); err != nil {
			return 1, err
		}
	case err == nil:
	default:
	}

	p, err := readTemplate("kd.yaml")
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

		if len(creds) == 1 {
			ident = creds[0].Identifier
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

	fmt.Printf("Create new stack...\n\n")
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

type lock struct {
	Stack struct {
		ID    string `yaml:"id"`
		Title string `yaml:"title"`
	} `yaml:"stack"`
}

func trylock() error {
	p, err := ioutil.ReadFile(".kd.lock")
	if os.IsNotExist(err) {
		return nil
	}
	if err != nil {
		return err
	}

	var l lock

	if err := yaml.Unmarshal(p, &l); err != nil {
		return err
	}

	return fmt.Errorf("Project already initialized with %q stack (%s)", l.Stack.Title, l.Stack.ID)
}

func writelock(id, title string) error {
	var l lock
	l.Stack.ID = id
	l.Stack.Title = title

	p, err := yaml.Marshal(&l)
	if err != nil {
		return err
	}

	return ioutil.WriteFile(".kd.lock", p, 0644)
}

func readTemplate(file string) ([]byte, error) {
	p, err := ioutil.ReadFile(file)
	if err != nil {
		return nil, err
	}

	var m map[string]interface{}

	if err := yaml.Unmarshal(p, &m); err != nil {
		return nil, err
	}

	return json.Marshal(object.FixYAML(m))
}
