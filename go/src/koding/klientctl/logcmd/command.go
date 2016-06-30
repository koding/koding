package logcmd

import (
	"errors"
	"io"
	"koding/klient/logfetcher"
	"koding/klientctl/ctlcli"
	"koding/klientctl/util"
	"os"

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
	Stdout  *util.Fprint
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
		Stdout: util.NewFprint(i.Stdout),
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
		// TODO: !! Get from Service, for multi OS support
		c.Options.KdLogLocation = "/Library/Logs/kd.log"
	}

	if c.Options.KlientLogLocation == "" {
		// TODO: !! Get from Service, for multi OS support
		c.Options.KlientLogLocation = "/Library/Logs/klient.log"
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

	lines, err := logfetcher.GetOffsetLines(f, 1024, n)
	if err != nil {
		return err
	}

	for _, l := range lines {
		c.Stdout.Printlnf(l)
	}

	return nil
}

func (c *Command) tailLogs() error {
	if c.Options.KdLog {
		err := c.tailFile(c.Options.KdLogLocation, c.Options.Lines)
		if err != nil {
			return err
		}
	}

	if c.Options.KlientLog {
		err := c.tailFile(c.Options.KlientLogLocation, c.Options.Lines)
		if err != nil {
			return err
		}
	}

	return nil
}
