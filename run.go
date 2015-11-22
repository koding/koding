package main

import (
	"fmt"
	"os"
	"strings"

	"github.com/codegangsta/cli"
)

func RunCommandFactory(c *cli.Context) int {
	r, err := NewRunCommand()
	if err != nil {
		fmt.Printf("Error running command: '%s'\n", err)
		return 1
	}

	if len(c.Args()) < 2 {
		cli.ShowCommandHelp(c, "run")
		return 1
	}

	res, err := r.Run(c.Args()[0], c.Args()[1:])
	if err != nil {
		fmt.Printf("Error running command: '%s'\n", err)
		return 1
	}

	// Write to standard out stream.
	// NOTE: This stream can contain values even if exit status is not 0.
	os.Stderr.WriteString(res.Stdout)

	if res.ExitStatus != 0 {
		os.Stderr.WriteString(res.Stderr)
		return res.ExitStatus
	}

	return 0
}

type RunCommand struct {
	// Transport is communication layer between this and local klient.
	// This is used to run the command on the remote machine.
	Transport
}

func NewRunCommand() (*RunCommand, error) {
	klientKite, err := CreateKlientClient(NewKlientOptions())
	if err != nil {
		return nil, err
	}

	if err := klientKite.Dial(); err != nil {
		return nil, err
	}

	return &RunCommand{Transport: klientKite}, nil
}

func (r *RunCommand) Run(machine string, cmdWithArgs []string) (*ExecRes, error) {
	req := struct {
		Machine string
		Command string
	}{
		Machine: machine,
		Command: strings.Join(cmdWithArgs, " "),
	}
	raw, err := r.Tell("remote.exec", req)
	if err != nil {
		return nil, err
	}

	var res ExecRes
	if err := raw.Unmarshal(&res); err != nil {
		return nil, err
	}

	return &res, nil
}
