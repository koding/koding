package exec

import (
	"io"
	"os"
	"os/exec"
)

// CommandRun is a struct that behaves similarly to the normal golang exec.Command
// struct, but with a slight API change. The change allows a command executer to be
// stored in an interface with ease.
type CommandRun struct {
	Stdin  io.Reader
	Stdout io.Writer
	Stderr io.Writer
}

// Run creates and runs a exec.Command struct, configuring it as
// this struct is configured and returning the result.
func (c *CommandRun) Run(bin string, args ...string) error {
	cmd := exec.Command(bin, args...)
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	return cmd.Run()
}
