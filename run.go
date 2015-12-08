package main

import (
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"syscall"

	"github.com/codegangsta/cli"
)

// ErrNotInMount happens when command is run from outside a mount.
var ErrNotInMount = errors.New("command not run on mount")

// RunCommandFactory is the factory method for RunCommand.
func RunCommandFactory(c *cli.Context) int {
	if len(c.Args()) < 1 {
		cli.ShowCommandHelp(c, "run")
		return 1
	}

	// get the path where the command was run
	localPath, err := filepath.Abs(filepath.Dir(os.Args[0]))
	if err != nil {
		fmt.Printf("Error running command: '%s'\n", err)
		return 1
	}

	r, err := NewRunCommand()
	if err != nil {
		fmt.Printf("Error running command: '%s'\n", err)
		return 1
	}

	var (
		cmdWithArgs    = os.Args[2:]
		cmdWithArgsStr = strings.Join(cmdWithArgs, " ")
	)

	res, err := r.runOnRemote(localPath, cmdWithArgsStr)
	if err != nil && err != ErrNotInMount {
		fmt.Printf("Error running command: '%s'\n", err)
		return 1
	}

	if err == ErrNotInMount {
		fmt.Println("Running on local:", cmdWithArgsStr)
		return r.runOnLocal(cmdWithArgs)
	}

	fmt.Println("Running on remote:", cmdWithArgsStr)

	// write to standard out stream
	// this stream can contain values even if exit status is not 0.
	os.Stderr.WriteString(res.Stdout)

	if res.ExitStatus != 0 {
		os.Stderr.WriteString(res.Stderr)
		return res.ExitStatus
	}

	return 0
}

// RunCommand is the cli command that lets users run a command a remote
// machine. All arguments/flags passed to command are sent to command run on
// remote machine.
//
// It currently only supports running commands from inside a mount. It detects
// if it's inside a mount by parsing the lock files and checking if command path
// is the same as or inside the mount.
type RunCommand struct {
	// Transport is communication layer between this and local klient.
	// This is used to run the command on the remote machine.
	Transport
}

// NewRunCommand is the required initializer for RunCommand.
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

func (r *RunCommand) runOnRemote(localPath string, cmdWithArgsStr string) (*ExecRes, error) {
	machine, err := GetMachineMountedForPath(localPath)
	if err != nil {
		return nil, err
	}

	fullCmdPath, err := r.getCmdRemotePath(machine, localPath)
	if err != nil {
		return nil, err
	}

	return r.runOnMachine(machine, fullCmdPath, cmdWithArgsStr)
}

func (r *RunCommand) runOnMachine(machine, fullCmdPath string, cmdWithArgsStr string) (*ExecRes, error) {
	req := struct {
		Machine string
		Command string
		Path    string
	}{
		Machine: machine,
		Command: cmdWithArgsStr,
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

// getCmdRemotePath return the path on remote machine where the command should
// be run.
func (r *RunCommand) getCmdRemotePath(machine, localPath string) (string, error) {
	relativePath, err := GetRelativeMountPath(localPath)
	if err != nil {
		return "", err
	}

	mounts, err := r.getMounts()
	if err != nil {
		return "", err
	}

	for _, m := range mounts {
		if m.MountName == machine {
			// join path in remote machine
			return filepath.Join(m.RemotePath, relativePath), nil
		}
	}

	return "", ErrNotInMount
}

// getMounts returns list of mounts from remote.
func (r *RunCommand) getMounts() ([]kiteMounts, error) {
	res, err := r.Tell("remote.mounts")
	if err != nil {
		return nil, err
	}

	var mounts []kiteMounts
	if err := res.Unmarshal(&mounts); err != nil {
		return nil, err
	}

	return mounts, nil
}

func (r *RunCommand) runOnLocal(cmdWithArgs []string) int {
	cmd := exec.Command(cmdWithArgs[0], cmdWithArgs[1:]...)
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	if err := cmd.Run(); err != nil {
		exitErr, ok := err.(*exec.ExitError)
		if !ok {
			fmt.Printf("Error running command: '%s'\n", err)
			return 1
		}

		return exitErr.Sys().(syscall.WaitStatus).ExitStatus()
	}

	return 1
}
