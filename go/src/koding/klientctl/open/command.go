package open

import (
	"errors"
	"fmt"
	"io"
	"koding/klient/kiteerrortypes"
	"koding/klientctl/ctlcli"
	"koding/klientctl/klient"
	"koding/klientctl/klientctlerrors"
	"koding/klientctl/util"
	"strings"

	"github.com/koding/logging"
)

// CLI options for the given command.
type Options struct {
	Debug     bool
	Filepaths []string
}

// Init contains various instances required for a Command instance to be initialized.
type Init struct {
	Stdout io.Writer
	Log    logging.Logger

	// The options to use if this struct needs to dial Klient.
	//
	// Note! These will be ignored if c.Klient is already defined before Run() is
	// called.
	KlientOptions klient.KlientOptions

	// The klient instance this struct will use.
	Klient interface {
		LocalOpenFiles(...string) error
	}

	// The ctlcli Helper. See the type docs for a better understanding of this.
	Helper ctlcli.Helper
}

func (i Init) CheckValid() error {
	if i.Stdout == nil {
		return errors.New("missing argument: Stdout")
	}

	if i.Log == nil {
		return errors.New("missing argument: Log")
	}

	if i.Helper == nil {
		return errors.New("missing argument: Helper")
	}

	return nil
}

// Command implements the klientctl.Command interface for `kd open`
type Command struct {
	// Embedded Init gives us our Klient/etc instances.
	Init
	Options Options
	Stdout  *util.Fprint

	// do not print an error's err.Error() string at the end of running. This
	// is useful to use a custom error message for specific errors.
	dontPrintErr bool
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

func (c *Command) Run() (exit int, err error) {
	defer func() {
		if err != nil && !c.dontPrintErr {
			c.Stdout.Printlnf(err.Error())
		}
	}()

	if err := c.setupKlient(); err != nil {
		return 1, err
	}

	if err := c.runOpen(); err != nil {
		return 1, err
	}

	return 0, nil
}

// setupKlient creates and dials our Kite interface *only* if it is nil. If it is
// not nil, someone else gave a kite to this Command, and it is expected to be
// dialed and working.
func (c *Command) setupKlient() error {
	// if c.klient isnt nil, don't overrite it. Another command may have provided
	// a pre-dialed klient.
	if c.Klient != nil {
		return nil
	}

	k, err := klient.NewDialedKlient(c.KlientOptions)
	if err != nil {
		return fmt.Errorf("failed to get working klient instance: %s", err)
	}

	c.Klient = k

	return nil
}

func (c *Command) runOpen() error {
	paths, err := PreparePaths(c.Options.Filepaths)
	if err != nil {
		return fmt.Errorf("failed to parse files and directories: %s", err)
	}

	if err := Mkfiles(paths, 0644); err != nil {
		return fmt.Errorf("failed to create files or directories: %s", err)
	}

	files, dirs, err := FileOrDir(paths)
	if err != nil {
		return fmt.Errorf("failed to split files and directories: %s", err)
	}

	if len(dirs) != 0 {
		c.Stdout.Printlnf(
			`Directories cannot be opened in the WebIDE.
Ignoring the following directories:
    %s`,
			strings.Join(dirs, "\n    "))
	}

	if err := c.Klient.LocalOpenFiles(files...); err != nil {
		if klientctlerrors.IsKiteOfTypeErr(err, kiteerrortypes.NoSubscribers) {
			c.dontPrintErr = true
			c.Stdout.Printlnf(`Unable to open the requested files on the Koding UI.

Please make sure this machine is visible on the Koding UI, and that you're
viewing it. If needed, refresh your browser so that Koding UI properly listens for
this "open files" request.`)
			return err
		}

		return fmt.Errorf("failed to talk to open files: %s", err)
	}

	return nil
}
