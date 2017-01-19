package daemon

import (
	"io"
	"os"

	"koding/kites/config"
	"koding/klientctl/endpoint/kloud"

	"github.com/koding/logging"
)

var DefaultClient = &Client{}

type Client struct {
	Stdin  io.Reader
	Stdout io.Writer
	Stderr io.Writer
	Cache  *config.Cache
	Log    logging.Logger
}

type InstallOpts struct {
	Force bool
}

func (c *Client) Install(opts *InstallOpts) error {
	return nil
}

type UninstallOpts struct {
	Force bool
}

func (c *Client) Uninstall(opts *UninstallOpts) error {
	return nil
}

type UpdateOpts struct {
	Force bool
}

func (c *Client) Update(opts *UpdateOpts) error {
	return nil
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

func (c *Client) cache() *config.Cache {
	if c.Cache != nil {
		return c.Cache
	}
	return kloud.DefaultClient.Cache()
}

func Install(opts *InstallOpts) error     { return DefaultClient.Install(opts) }
func Uninstall(opts *UninstallOpts) error { return DefaultClient.Uninstall(opts) }
func Update(opts *UpdateOpts) error       { return DefaultClient.Update(opts) }
func Start() error                        { return DefaultClient.Start() }
func Restart() error                      { return DefaultClient.Restart() }
func Stop() error                         { return DefaultClient.Stop() }
func Status() error                       { return DefaultClient.Status() }
