package daemon

import (
	"io"
	"os"
	"sync"

	"koding/kites/config"
	conf "koding/klientctl/config"
	"koding/klientctl/ctlcli"
	konfig "koding/klientctl/endpoint/config"

	"github.com/koding/logging"
)

var DefaultClient = &Client{}

type Client struct {
	Stdin       io.Reader
	Stdout      io.Writer
	Stderr      io.Writer
	Konfig      *config.Konfig
	KonfigCache *config.Cache
	Log         logging.Logger
	Script      []InstallStep

	once    sync.Once
	details *Details
}

func (c *Client) Start() error {
	return nil
}

func (c *Client) Restart() error {
	return nil
}

func (c *Client) Stop() error {
	return nil
}

func (c *Client) Status() error {
	return nil
}

func (c *Client) Close() (err error) {
	if c.details != nil {
		err = c.konfigCache().GetValue("daemon.details", c.details)
	}
	return err
}

func (c *Client) init() {
	c.once.Do(c.readCache)
}

func (c *Client) readCache() {
	c.details = newDetails()

	// Ignoring read error, if it's non-nil then empty cache is going to
	// be used instead.
	_ = c.konfigCache().GetValue("daemon.details", c.details)

	if c == DefaultClient {
		ctlcli.CloseOnExit(c)
	}
}

func (c *Client) stdin() io.Reader {
	if c.Stdin != nil {
		return c.Stdin
	}
	return os.Stdin
}

func (c *Client) stdout() io.Writer {
	if c.Stdout != nil {
		return c.Stdout
	}
	return os.Stdout
}

func (c *Client) stderr() io.Writer {
	if c.Stderr != nil {
		return c.Stderr
	}
	return os.Stderr
}

func (c *Client) konfig() *config.Konfig {
	if c.Konfig != nil {
		return c.Konfig
	}
	return conf.Konfig
}

func (c *Client) konfigCache() *config.Cache {
	if c.KonfigCache != nil {
		return c.KonfigCache
	}
	return konfig.Cache()
}

func (c *Client) script() []InstallStep {
	if c.Script != nil {
		return c.Script
	}
	return script
}

func min(i, j int) int {
	if i < j {
		return i
	}
	return j
}

func Install(opts *InstallOpts) error     { return DefaultClient.Install(opts) }
func Uninstall(opts *UninstallOpts) error { return DefaultClient.Uninstall(opts) }
func Update(opts *UpdateOpts) error       { return DefaultClient.Update(opts) }
func Start() error                        { return DefaultClient.Start() }
func Restart() error                      { return DefaultClient.Restart() }
func Stop() error                         { return DefaultClient.Stop() }
func Status() error                       { return DefaultClient.Status() }
