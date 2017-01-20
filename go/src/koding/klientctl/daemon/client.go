package daemon

import (
	"io"
	"os"
	"sync"

	"koding/kites/config"
	conf "koding/klientctl/config"
	"koding/klientctl/ctlcli"
	konfig "koding/klientctl/endpoint/config"
	"koding/klientctl/endpoint/kloud"

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

	once sync.Once
	d    *Details
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
	if c.d != nil {
		err = c.konfigCache().SetValue("daemon.details", c.d)
	}
	return err
}

func (c *Client) init() {
	c.once.Do(c.readCache)
}

func (c *Client) readCache() {
	c.d = newDetails()

	// Ignoring read error, if it's non-nil then empty cache is going to
	// be used instead.
	_ = c.konfigCache().GetValue("daemon.details", c.d)

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

func (c *Client) kd(version int) string {
	return conf.S3Klientctl(version, c.konfig().Environment)
}

func (c *Client) klient(version int) string {
	return conf.S3Klient(version, c.konfig().Environment)
}

func (c *Client) kdLatest() string {
	return c.konfig().Endpoints.KDLatest.Public.String()
}

func (c *Client) klientLatest() string {
	return c.konfig().Endpoints.KlientLatest.Public.String()
}

func (c *Client) script() []InstallStep {
	if c.Script != nil {
		return c.Script
	}
	return script
}

func (c *Client) log() logging.Logger {
	if c.Log != nil {
		return c.Log
	}
	return kloud.DefaultLog
}

func min(i, j int) int {
	if i < j {
		return i
	}
	return j
}

func Install(opts *Opts) error   { return DefaultClient.Install(opts) }
func Uninstall(opts *Opts) error { return DefaultClient.Uninstall(opts) }
func Update(opts *Opts) error    { return DefaultClient.Update(opts) }
func Start() error               { return DefaultClient.Start() }
func Restart() error             { return DefaultClient.Restart() }
func Stop() error                { return DefaultClient.Stop() }
func Status() error              { return DefaultClient.Status() }
