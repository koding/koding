package cli

import (
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"sort"
	"strconv"
	"strings"

	"koding/kites/metrics"
	"koding/klientctl/config"
	"koding/klientctl/helper"
	"koding/klientctl/util"

	"github.com/koding/logging"
	"github.com/spf13/cobra"
)

// PrintJSON converts provided object to formatted JSON string and writes it to w.
func PrintJSON(w io.Writer, v interface{}) {
	enc := json.NewEncoder(w)
	enc.SetEscapeHTML(false)
	enc.SetIndent("", "\t")
	enc.Encode(v)
}

// AskList returns a function which either asks to select one of provided items
// or returns error when interactive mode is disabled. This function is no-op
// when there is only one provided item.
func AskList(c *CLI, cmd *cobra.Command) func([]string, []string) (string, error) {
	noninteractive, _ := cmd.Flags().GetBool("force")
	if _, ok := os.LookupEnv("KD_NONINTERACTIVE"); ok {
		noninteractive = true
	}

	return func(items, descriptions []string) (string, error) {
		if len(items) == 0 {
			return "", fmt.Errorf("no items provided")
		}

		if len(items) == 1 {
			return items[0], nil
		}

		if noninteractive {
			return "", fmt.Errorf("ambiguous identifier (matches: %s)", strings.Join(items, ","))
		}

		if len(items) != len(descriptions) {
			return "", fmt.Errorf("invalid number of item descriptions")
		}

		for i, desc := range descriptions {
			fmt.Fprintf(c.Out(), "[%d] %s\n", i+1, desc)
		}

		value, err := helper.Fask(c.In(), c.Out(),
			"More than one items match provided identifier. Which one did you mean? [1-%d]: ", len(items))
		if err != nil {
			return "", err
		}

		idx, err := strconv.Atoi(value)
		if err != nil {
			return "", fmt.Errorf("invalid option provided %q", value)
		}
		if idx < 0 || idx >= len(items) {
			return "", fmt.Errorf("value %d not in provided range", idx)
		}

		return items[idx], nil
	}
}

// CLI represents the kd command line client that stores data streams and basic
// information about kd state.
type CLI struct {
	in  io.ReadCloser // input stream.
	out io.Writer     // output stream.
	err io.Writer     // error stream.

	m *metrics.Metrics // usage metrics.

	debug bool
	log   logging.Logger
	mds   map[string][]func() string // debug info about middlewares.
}

// NewCLI creates a new CLI client.
func NewCLI(in io.ReadCloser, out, err, logHandler io.Writer) *CLI {
	c := &CLI{
		in:    in,
		out:   out,
		err:   err,
		debug: isDebug(),
		log:   newLogger(logHandler),
		mds:   make(map[string][]func() string),
	}

	if !config.Konfig.DisableMetrics {
		if m, err := metrics.New("kd"); err != nil {
			c.Log().Warning("Metrics will not be collected: %v", err)
		} else {
			c.m = m
		}
	}

	return c
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

// Middlewares return debug information about middlewares and commands they wrap.
func (c *CLI) Middlewares() map[string][]string {
	all := make(map[string][]string)
	for m, fs := range c.mds {
		for _, f := range fs {
			all[m] = append(all[m], f())
		}
	}

	for m := range all {
		sort.Strings(all[m])
	}

	return all
}

func (c *CLI) registerMiddleware(name string, cmd *cobra.Command) {
	f := func() (desc string) {
		desc = cmd.CommandPath()
		if aliasPath := cmd.Annotations[AliasAnnotation]; len(aliasPath) != 0 {
			desc += " (alias: " + aliasPath + ")"
		}

		return desc
	}

	c.mds[name] = append(c.mds[name], f)
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

func newLogger(w io.Writer) logging.Logger {
	if w == nil {
		w = ioutil.Discard
	}

	handler := logging.NewWriterHandler(w)

	// Make handler writer accept all incoming log messages.
	handler.SetLevel(logging.DEBUG)

	logger := logging.NewCustom("kd", isDebug())
	logger.SetHandler(handler)

	return logger
}

func isDebug() bool {
	return os.Getenv("KD_DEBUG") == "1" || config.Konfig.Debug
}
