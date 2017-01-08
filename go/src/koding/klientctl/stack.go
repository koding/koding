package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"io/ioutil"
	"os"

	"koding/klientctl/endpoint/stack"

	"github.com/codegangsta/cli"
	"github.com/koding/logging"
)

func StackCreate(c *cli.Context, log logging.Logger, _ string) (int, error) {
	var p []byte
	var err error

	switch file := c.String("file"); file {
	case "":
		return 1, errors.New("no template file was provided")
	case "-":
		p, err = ioutil.ReadAll(os.Stdin)
	default:
		p, err = ioutil.ReadFile(file)
	}

	if err != nil {
		return 1, errors.New("error reading template file: " + err.Error())
	}

	fmt.Println("Creating stack... ")

	opts := &stack.CreateOptions{
		Team:        c.String("team"),
		Title:       c.String("title"),
		Credentials: c.StringSlice("credential"),
		Template:    p,
	}

	resp, err := stack.Create(opts)
	if err != nil {
		return 1, errors.New("error creating stack: " + err.Error())
	}

	if c.Bool("json") {
		enc := json.NewEncoder(os.Stdout)
		enc.SetIndent("", "\t")
		enc.Encode(res)

		return 0, nil
	}

	fmt.Fprintf(os.Stderr, "Creatad %q stack with %s ID.\n", resp.Title, resp.StackID)

	return 0, nil
}
