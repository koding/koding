package ctlcli

import (
	"io"
	"koding/klientctl/util"

	"github.com/koding/logging"
)

// ErrorCommand implements a Command interface for an error - printing the error
// or a custom message when Run is called.
type ErrorCommand struct {
	Stdout  *util.Fprint
	Log     logging.Logger
	Message string
	Error   error
}

func NewErrorCommand(stdout io.Writer, log logging.Logger, err error, msg string) *ErrorCommand {
	return &ErrorCommand{
		Stdout:  util.NewFprint(stdout),
		Log:     log.New("errorCommand"),
		Message: msg,
		Error:   err,
	}
}

// Print the message to the user if not empty, otherwise print the error string.
func (c *ErrorCommand) Print() {
	if c.Message != "" {
		c.Stdout.Printlnf(c.Message)
	} else {
		c.Stdout.Printlnf(c.Error.Error())
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
