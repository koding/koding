package cli

import (
	"io"
	"io/ioutil"
	"os"

	"koding/kites/metrics"
	"koding/klientctl/config"
	"koding/klientctl/util"

	"github.com/koding/logging"
)

// CLI represents the kd command line client that stores data streams and basic
// information about kd state.
type CLI struct {
	in  io.ReadCloser // input stream.
	out io.Writer     // output stream.
	err io.Writer     // error stream.

	m *metrics.Metrics // usage metrics.

	debug bool
	log   logging.Logger
}

// NewCLI creates a new CLI client.
func NewCLI(in io.ReadCloser, out, err, logHandler io.Writer) *CLI {
	c := &CLI{
		in:    in,
		out:   out,
		err:   err,
		debug: isDebug(),
		log:   newLogger(logHandler),
	}

	if !config.Konfig.DisableMetrics {
		if m, err = metrics.New("kd"); err != nil {
			c.Log().Warning("Metrics will not be collected: %v", err)
		} else {
			c.m = m
		}
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

// Metrics returns metrics client or nil if not enabled.
func (c *CLI) Metrics() *metrics.Metrics {
	return c.m
}

// IsDebug returns true when debug mode is enabled.
func (c *CLI) IsDebug() bool {
	return isDebug()
}

// IsAdmin checks whether or not the current user has admin privileges.
func (c *CLI) IsAdmin() (bool, error) {
	return util.NewPermissions().IsAdmin()
}

// Close closes all resources managed by CLI object.
func (c *CLI) Close() (err error) {
	if c.in != nil {
		err = c.in.Close()
	}

	if c.m != nil {
		if ee := c.m.Close(); ee != nil && err == nil {
			err = ee
		}
	}

	return
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
