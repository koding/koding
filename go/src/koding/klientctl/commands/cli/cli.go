package cli

import (
	"io"
	"io/ioutil"
	"os"

	"koding/klientctl/config"

	"github.com/koding/logging"
	"github.com/spf13/cobra"
)

// CobraFuncE is a shortcut for cobra operation handlers that retturn errors.
type CobraFuncE func(cmd *cobra.Command, args []string) error

// UnionCobraFuncE creates a new cobra handler which calls first and next
// functions respectively.
func UnionCobraFuncE(first, next ...CobraFuncE) CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		for _, f := range append([]CobraFuncE{first}, next...) {
			if f == nil {
				continue
			}

			if err := f(cmd, args); err != nil {
				return err
			}
		}

		return nil
	}
}

// CLI represents the kd command line client that stores data streams and basic
// information about kd state.
type CLI struct {
	in  io.ReadCloser // input stream.
	out io.Writer     // output stream.
	err io.Writer     // error stream.

	debug bool
	log   logging.Logger
}

// NewCLI creates a new CLI client.
func NewCLI(in io.ReadCloser, out, err, logHandler io.Writer) *CLI {
	return &CLI{
		in:    in,
		out:   out,
		err:   err,
		debug: isDebug(),
		log:   newLogger(logHandler),
	}
}

// In returns CLI's input stream. Defaults to standard input when nil.
func (c *CLI) In() io.Reader {
	if c.in != nil {
		return c.in
	}

	return os.Stdin
}

// Out returns CLI's output stream. Defaults to standard output when nil.
func (c *CLI) Out() io.Writer {
	if c.out != nil {
		return c.out
	}

	return os.Stdout
}

// Err return CLI's error stream. Defaults to standard error when nil.
func (c *CLI) Err() io.Writer {
	if c.err != nil {
		return c.err
	}

	return os.Stderr
}

// Log returns CLI's logger. Defaults to discard logger when nil.
func (c *CLI) Log() logging.Logger {
	if c.log != nil {
		return c.log
	}

	return newLogger(nil)
}

// IsDebug returns true when debug mode is enabled.
func (c *CLI) IsDebug() bool {
	return isDebug()
}

// Close closes all resources managed by CLI object.
func (c *CLI) Close() error {
	if c.in != nil {
		return c.in.Close()
	}

	return nil
}

func newLogger(handler io.Writer) logging.Logger {
	if handler == nil {
		handler = ioutil.Discard
	}

	logger := logging.NewLogger("kd")
	logger.SetHandler(handler)

	if isDebug() {
		logger.SetLevel(logging.DEBUG)
	}

	return logger
}

func isDebug() bool {
	return os.Getenv("KD_DEBUG") == "1" || config.Konfig.Debug
}
