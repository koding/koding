package ctlcli

import (
	"fmt"
	"io"

	"github.com/koding/logging"
)

// ErrorCommand implements a Command interface for an error - printing the error
// or a custom message when Run is called.
type ErrorCommand struct {
	Stdout  io.Writer
	Log     logging.Logger
	Message string
	Error   error
}

func NewErrorCommand(stdout io.Writer, log logging.Logger, err error, msg string) *ErrorCommand {
	return &ErrorCommand{
		Stdout:  stdout,
		Log:     log.New("errorCommand"),
		Message: msg,
		Error:   err,
	}
}

// Print the message to the user if not empty, otherwise print the error string.
func (c *ErrorCommand) Print() {
	if c.Message != "" {
		fmt.Fprintln(c.Stdout, c.Message)
	} else {
		fmt.Fprintln(c.Stdout, c.Error.Error())
	}
}

func (c *ErrorCommand) Help() {
	log := c.Log.New("#help")
	log.Error("Original command could not be created. originalErr:%s", c.Error)
	c.Print()
}

func (c *ErrorCommand) Run() (int, error) {
	log := c.Log.New("#run")
	log.Error("Original command could not be created. originalErr:%s", c.Error)
	c.Print()
	return 1, c.Error
}
