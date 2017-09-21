package logcmd

import (
	"errors"
	"fmt"
	"io"
	"os"

	"koding/klient/logfetcher"
	"koding/klientctl/config"
	"koding/klientctl/ctlcli"

	"github.com/koding/logging"
)

// Options for the command, generally mapped 1:1 to
// CLI options for the given command.
type Options struct {
	Debug             bool
	Lines             int
	KdLog             bool
	KlientLog         bool
	KdLogLocation     string
	KlientLogLocation string
}

// Init contains various instances required for a Command instance to be initialized.
type Init struct {
	Stdout io.Writer
	Log    logging.Logger

	// The ctlcli Helper. See the type docs for a better understanding of this.
	Helper ctlcli.Helper
}

func (i Init) CheckValid() error {
	if i.Stdout == nil {
		return errors.New("MissingArgument: Stdout")
	}

	if i.Log == nil {
		return errors.New("MissingArgument: Log")
	}

	if i.Helper == nil {
		return errors.New("MissingArgument: Helper")
	}

	return nil
}

// Command implements the klientctl.Command interface for `kd sync`
type Command struct {
	// Embedded Init gives us our Klient/etc instances.
	Init
	Options Options
	Stdout  io.Writer
}

func NewCommand(i Init, o Options) (*Command, error) {
	if err := i.CheckValid(); err != nil {
		return nil, err
	}

	if o.Debug {
		i.Log.SetLevel(logging.DEBUG)
	}

	c := &Command{
		Init:    i,
		Options: o,
		// Override the init stdout writer with an Fprint writer
		Stdout: i.Stdout,
	}

	return c, nil
}

// Help prints help to the caller.
func (c *Command) Help() {
	c.Helper(c.Stdout)
}

func (c *Command) Run() (int, error) {
	if err := c.handleOptions(); err != nil {
		return 1, err
	}

	if err := c.tailLogs(); err != nil {
		return 2, err
	}

	return 0, nil
}

// handleOptions deals with options, erroring if options are missing, etc.
func (c *Command) handleOptions() error {
	if c.Options.KdLogLocation == "" {
		c.Options.KdLogLocation = config.GetKdLogPath()
	}

	if c.Options.KlientLogLocation == "" {
		c.Options.KlientLogLocation = config.GetKlientLogPath()
	}

	if c.Options.Lines == 0 {
		c.Options.Lines = 20
	}

	return nil
}

func (c *Command) tailFile(path string, n int) error {
	f, err := os.OpenFile(path, os.O_RDONLY, 0600)
	if err != nil {
		return err
	}

	// NOTE(leeola): On some systems, seemingly at random, the opened file is
	// nil. The resulting error would come from GetOffsetLines' use of Seek,
	// complaining about an invalid argument.
	//
	// To be a bit less obtuse, i'm returning a custom message and error here.
	if f == nil {
		c.Log.Warning("Nil file encountered, with no error explaining why. path:%s", path)
		return fmt.Errorf("File opened without err, but file is nil. path:%s", path)
	}
	defer f.Close()

	lines, err := logfetcher.GetOffsetLines(f, 1024, n)
	if err != nil {
		return err
	}

	for _, l := range lines {
		fmt.Fprintln(c.Stdout, l)
	}

	return nil
}

func (c *Command) tailLogs() (err error) {
	if c.Options.KdLog {
		logLoc := c.Options.KdLogLocation
		err = c.tailFile(logLoc, c.Options.Lines)

		// Just logging here, because we want to print both logs if possible.
		if err != nil {
			c.Log.Error("Tailing %q returned err: %s", logLoc, err)
		}
	}

	if c.Options.KlientLog {
		logLoc := c.Options.KlientLogLocation
		err = c.tailFile(logLoc, c.Options.Lines)
		// Just logging here, because we want to print both logs if possible.
		if err != nil {
			c.Log.Error("Tailing %q returned err: %s", logLoc, err)
		}
	}

	return err
}
