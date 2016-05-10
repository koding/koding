// Package command provides kite.handleFuncs to run and spawn processes
package command

import (
	"bytes"
	"errors"
	"os/exec"
	"syscall"

	"github.com/koding/kite"

	"koding/klient/kiteerrortypes"
	"koding/klient/util"
)

// Output defines the response of an executed command.
type Output struct {
	Stdout     string `json:"stdout"`
	Stderr     string `json:"stderr"`
	ExitStatus int    `json:"exitStatus"`
}

// NewOuput runs the given cmd and returns the output
func NewOutput(cmd *exec.Cmd) (*Output, error) {
	stdoutBuffer, stderrBuffer := new(bytes.Buffer), new(bytes.Buffer)
	cmd.Stdout, cmd.Stderr = stdoutBuffer, stderrBuffer
	var exitStatus int

	err := cmd.Run()
	if err != nil {
		if exitErr, ok := err.(*exec.ExitError); !ok {
			// return if it's not an exitError
			return nil, util.NewKiteError(kiteerrortypes.ProcessError, err)
		} else {
			exitStatus = exitErr.Sys().(syscall.WaitStatus).ExitStatus()
		}
	}

	return &Output{
		Stdout:     stdoutBuffer.String(),
		Stderr:     stderrBuffer.String(),
		ExitStatus: exitStatus,
	}, nil
}

// Exec executes the given command and returns a command.Output struct if
// successful. If `async` is enabled it starts the command but does wait for it
// complete.
func Exec(r *kite.Request) (interface{}, error) {
	var params struct {
		Command string
		Async   bool
	}

	if r.Args.One().Unmarshal(&params) != nil || params.Command == "" {
		return nil, errors.New("{command : [string]}")
	}

	if params.Async {
		err := exec.Command("/bin/bash", "-c", params.Command).Start()
		if err != nil {
			return nil, err
		}
	}

	cmd := exec.Command("/bin/bash", "-c", params.Command)
	return NewOutput(cmd)
}
