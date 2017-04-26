package daemon

import (
	"errors"
	"fmt"
	"net/http"
	"sync"
	"time"

	"koding/kites/config"
	"koding/kites/config/configstore"
	conf "koding/klientctl/config"
	"koding/klientctl/ctlcli"
	"koding/klientctl/endpoint/auth"
	"koding/klientctl/endpoint/kloud"

	"github.com/koding/logging"
)

// TODO(rjeczalik): emit events and move printing to stdout
// to cli instead.

// DefaultClient is a default client used for daemon package-level functions.
var DefaultClient = &Client{}

func init() {
	ctlcli.CloseOnExit(DefaultClient)
}

// Client is used to configure behaviour of daemon package
// functionality like install / uninstall and start / stop.
type Client struct {
	Konfig  *config.Konfig      // configuration to use; by default config.Konfig
	Store   *configstore.Client // cache to use; be default configstore.DefaultClient
	Log     logging.Logger      // logger to use; by default kloud.DefaultLog
	Script  []InstallStep       // installation script to use; by default Script is used
	Timeout time.Duration       // max time to wait for daemon to be ready; by default 20s

	once      sync.Once
	d         *Details
	vagrant   *bool
	uninstall bool
}

// Starts starts KD daemon.
func (c *Client) Start() error {
	c.init()

	svc, err := c.d.service()
	if err != nil {
		return err
	}

	fmt.Printf("Starting daemon service... ")

	if err = svc.Start(); err != nil {
		return err
	}

	fmt.Printf("ok\nWaiting for the daemon to become ready... ")

	if err := c.Ping(); err != nil {
		return err
	}

	fmt.Println("ok")

	return nil
}

// Restart stops the KD daemon and starts it afterwards.
//
// Stop failure is ignored, e.g. when daemon is not running.
func (c *Client) Restart() error {
	_ = c.Stop()
	return c.Start()
}

// Stop stops the KD daemon.
func (c *Client) Stop() error {
	c.init()

	svc, err := c.d.service()
	if err != nil {
		return err
	}

	fmt.Printf("Stopping daemon service... ")

	if err := svc.Stop(); err != nil {
		return err
	}

	fmt.Println("ok")

	return nil
}

// Installed tells whether KD was installed for the current user.
func (c *Client) Installed() bool {
	c.init()

	return len(c.d.Installation) == len(Script)
}

// Ping probes KD daemon and returns nil error when it's ready.
func (c *Client) Ping() error {
	timeout := time.NewTimer(c.timeout())
	defer timeout.Stop()

	tick := time.NewTicker(time.Second)
	defer tick.Stop()

	err := errors.New("too small timeout")

	for {
		select {
		case <-tick.C:
			var resp *http.Response
			resp, err = http.Get(c.konfig().Endpoints.Klient.Private.String())
			if err != nil {
				c.log().Warning("ping: requesting /kite failed: %s", err)
				continue
			}
			resp.Body.Close() // ignore body

			switch resp.StatusCode {
			case http.StatusOK, http.StatusNoContent:
				return nil
			default:
				err = errors.New(http.StatusText(resp.StatusCode))
				c.log().Warning("ping: /kite request failed: %s", err)
			}
		case <-timeout.C:
			return fmt.Errorf("waiting for KD Daemon to become available timed out after %s: %s", c.timeout(), err)
		}
	}
}

// Close closes the client flushing any updated state information.
func (c *Client) Close() (err error) {
	if c.d != nil {
		err = c.store().Commit(func(cache *config.Cache) error {
			if c.uninstall {
				return cache.Delete("daemon.details")
			}

			return cache.SetValue("daemon.details", c.d)
		})
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
	_ = c.store().Commit(func(cache *config.Cache) error {
		return cache.GetValue("daemon.details", c.d)
	})
}

func (c *Client) newFacade() (*auth.Facade, error) {
	return auth.NewFacade(&auth.FacadeOptions{
		Base: c.d.base(),
		Log:  c.log(),
	})
}

func (c *Client) konfig() *config.Konfig {
	if c.Konfig != nil {
		return c.Konfig
	}
	return conf.Konfig
}

func (c *Client) store() *configstore.Client {
	if c.Store != nil {
		return c.Store
	}
	return configstore.DefaultClient
}

func (c *Client) kd(version int) string {
	return conf.S3Klientctl(version, conf.Environments.KDEnv)
}

func (c *Client) klient(version int) string {
	return conf.S3Klient(version, conf.Environments.KlientEnv)
}

func (c *Client) kdLatest() string {
	return c.konfig().Endpoints.KDLatest.Public.String()
}

func (c *Client) klientLatest() string {
	return config.ReplaceCustomEnv(c.konfig().Endpoints.KlientLatest, conf.Environments.Env, conf.Environments.KlientEnv).Public.String()
}

func (c *Client) script() []InstallStep {
	if c.Script != nil {
		return c.Script
	}
	return Script
}

func (c *Client) log() logging.Logger {
	if c.Log != nil {
		return c.Log
	}
	return kloud.DefaultLog
}

func (c *Client) timeout() time.Duration {
	if c.Timeout != 0 {
		return c.Timeout
	}
	return 20 * time.Second
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
func Installed() bool            { return DefaultClient.Installed() }
