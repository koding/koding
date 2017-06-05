package main

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	kstack "koding/kites/kloud/stack"
	"koding/klientctl/app"
	"koding/klientctl/config"
	"koding/klientctl/endpoint/credential"
	"koding/klientctl/endpoint/machine"
	"koding/klientctl/endpoint/team"
	"koding/klientctl/helper"

	"github.com/koding/logging"
	cli "gopkg.in/urfave/cli.v1"
)

func Live(c *cli.Context, log logging.Logger, _ string) (int, error) {
	if err := isLocked(); err != nil {
		return 1, err
	}

	var vars map[string]string

	if _, err := os.Stat(config.Konfig.Template.File); os.IsNotExist(err) {
		fmt.Printf("Initializing with new %s template file...\n\n", config.Konfig.Template.File)

		var err error
		if vars, err = templateInit(config.Konfig.Template.File, false, ""); err != nil {
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

	opts := &app.StackOptions{
		Team:        team.Used().Name,
		Credentials: []string{ident},
		Template:    p,
	}

	stack, machines, err := app.BuildStack(opts)
	if err != nil {
		return 1, err
	}

	// copy files

	wd, err := os.Getwd()
	if err != nil {
		return 1, err
	}

	cpOpts := &machine.CpOptions{
		Identifier:      machines[0].ID,
		SourcePath:      wd,
		DestinationPath: filepath.FromSlash("/var/lib/koding/app/"),
		Log:             log.New("cp"),
	}

	fmt.Fprintf(os.Stderr, "\nUploading project files from current directory to your remote...\n\n")

	if err := machine.Cp(cpOpts); err != nil {
		return 1, err
	}

	// build application

	fmt.Fprintf(os.Stderr, "\nBiulding your project...\n\n")

	done := make(chan int, 1)
	fn := func(line string) {
		fmt.Fprintf(os.Stderr, "%s | %s\n", machines[0].Slug, line)
	}

	execOpts := &machine.ExecOptions{
		MachineID:     machines[0].ID,
		Cmd:           "/var/lib/koding/run",
		Stdout:        fn,
		Stderr:        fn,
		Exit:          func(exit int) { done <- exit },
		WaitConnected: 30 * time.Second,
	}

	if _, err := machine.Exec(execOpts); err != nil {
		return 1, err
	}

	<-done

	_ = vars

	if err := writelock(stack.ID, *stack.Title); err != nil {
		return 1, err
	}

	return 0, nil
}
