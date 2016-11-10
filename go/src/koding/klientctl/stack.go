package main

import (
	"errors"
	"fmt"
	"io/ioutil"
	"os"

	"koding/klientctl/kloud/stack"

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

	fmt.Println("Creating stack... ")

	opts := &stack.CreateOptions{
		Team:        c.String("team"),
		Title:       c.String("title"),
		Credentials: c.StringSlice("credential"),
		Template:    p,
	}

	resp, err := stack.Create(opts)
	if err != nil {
		fmt.Fprintln(os.Stderr, "Error creating stack:", err)
		return 1, err
	}

	fmt.Fprintf(os.Stderr, "Creatad %q stack with %s ID.\n", resp.Title, resp.StackID)

	return 0, nil
}
