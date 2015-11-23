package main

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/codegangsta/cli"
)

var ErrNotInMount = errors.New("Command was not run on a mounted folder.")

func RunCommandFactory(c *cli.Context) int {
	dir, err := filepath.Abs(filepath.Dir(os.Args[0]))
	if err != nil {
		fmt.Printf("Error running command: '%s'\n", err)
		return 1
	}

	r, err := NewRunCommand(dir)
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

	// Path is the fully qualified path where this command is run. This is used
	// to lookup the relative path to run command on the remote machine.
	Path string
}

func NewRunCommand(path string) (*RunCommand, error) {
	klientKite, err := CreateKlientClient(NewKlientOptions())
	if err != nil {
		return nil, err
	}

	if err := klientKite.Dial(); err != nil {
		return nil, err
	}

	return &RunCommand{
		Transport: klientKite,
		Path:      path,
	}, nil
}

func (r *RunCommand) Run(machine string, cmdWithArgs []string) (*ExecRes, error) {
	fullCmdPath, err := r.getCmdRemotePath(machine)
	if err != nil && err != ErrNotInMount {
		return nil, err
	}

	req := struct {
		Machine string
		Command string
		Path    string
	}{
		Machine: machine,
		Command: strings.Join(cmdWithArgs, " "),
		Path:    fullCmdPath,
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

// getCmdRemotePath return the path on remote machine where the command
// should be run.
func (r *RunCommand) getCmdRemotePath(machine string) (string, error) {
	res, err := r.Tell("remote.mounts")
	if err != nil {
		return "", err
	}

	var mounts []kiteMounts
	if err := res.Unmarshal(&mounts); err != nil {
		return "", err
	}

	for _, m := range mounts {
		if isMachineMatchPartial(m.MountName, machine) {
			// hacky way to determine if command was run outside mounted path
			if len(m.LocalPath) > len(r.Path) {
				return "", ErrNotInMount
			}

			s := strings.Split(r.Path, m.LocalPath) // find path in mounted folder
			p := filepath.Join(s...)                // join split path
			r := filepath.Join(m.RemotePath, p)     // join path in remote machine

			return r, nil
		}
	}

	return "", ErrNotInMount
}

func isMachineMatchPartial(m1, m2 string) bool {
	return m1 == m2 || strings.HasPrefix(m1, m2)
}
