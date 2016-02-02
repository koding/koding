package tunnelproxy

import (
	"fmt"
	"net"
	"net/url"
	"time"

	"koding/kites/common"

	"github.com/cenkalti/backoff"
	"github.com/koding/kite"
	"github.com/koding/kite/config"
	"github.com/koding/logging"
	"github.com/koding/tunnel"
)

const (
	ClientKiteName    = "tunnelclient"
	ClientKiteVersion = "0.0.1"
)

type ClientOptions struct {
	ServerAddr  string
	LocalAddr   string
	VirtualHost string
	Debug       bool
	Config      *config.Config
	Log         logging.Logger
	NoTLS       bool

	Timeout time.Duration // used in tests; for production no timeout
}

type Client struct {
	VirtualHost string
	Client      *tunnel.Client

	kite    *kite.Kite
	tserver *kite.Client
	opts    *ClientOptions
}

func NewClient(opts *ClientOptions) (*Client, error) {
	optsCopy := *opts
	optsCopy.Config = opts.Config.Copy()

	if _, _, err := net.SplitHostPort(optsCopy.ServerAddr); err != nil {
		port := ":443"
		if optsCopy.NoTLS {
			port = ":80"
		}

		optsCopy.ServerAddr = optsCopy.ServerAddr + port
	}
	if optsCopy.Log == nil {
		optsCopy.Log = common.NewLogger("tunnelclient", optsCopy.Debug)
	}

	c := &Client{
		kite: kite.New(ClientKiteName, ClientKiteVersion),
		opts: &optsCopy,
	}
	c.kite.Config = c.opts.Config

	tserverURL := &url.URL{
		Scheme: "https",
		Host:   c.opts.ServerAddr,
		Path:   "/kite",
	}

	if c.opts.NoTLS {
		tserverURL.Scheme = "http"
	}

	tserver, err := c.connect(tserverURL.String())
	if err != nil {
		return nil, err
	}

	c.tserver = tserver

	cfg := &tunnel.ClientConfig{
		ServerAddr:      optsCopy.ServerAddr,
		LocalAddr:       optsCopy.LocalAddr,
		FetchIdentifier: c.register,
		Debug:           c.opts.Debug,
		Log:             c.opts.Log.New("transport"),
	}

	client, err := tunnel.NewClient(cfg)
	if err != nil {
		return nil, err
	}

	c.Client = client

	return c, nil
}

func (c *Client) Start() error {
	c.opts.Log.Info("Connecting to tunnel server: %s", c.opts.ServerAddr)
	go c.Client.Start()
	<-c.Client.StartNotify()
	return c.waitDNS()
}

func (c *Client) Close() (err error) {
	if c.Client != nil {
		err = c.Client.Close()
	}
	if c.tserver != nil {
		c.tserver.Close()
	}
	if c.kite != nil {
		c.kite.Close()
	}
	return err
}

func (c *Client) register() (string, error) {
	req := &RegisterRequest{
		VirtualHost: c.opts.VirtualHost,
	}
	resp, err := c.tserver.TellWithTimeout("register", c.opts.Timeout, req)
	if err != nil {
		return "", err
	}

	c.opts.Log.Debug("Register response: %q", resp.Raw)

	var res RegisterResult
	if err := resp.Unmarshal(&res); err != nil {
		return "", err
	}

	c.VirtualHost = res.VirtualHost

	return res.Secret, nil
}

func (c *Client) connect(tserverURL string) (*kite.Client, error) {
	tserver := c.kite.NewClient(tserverURL)
	tserver.Reconnect = true
	tserver.Auth = &kite.Auth{
		Type: "kiteKey",
		Key:  c.opts.Config.KiteKey,
	}

	if c.opts.Timeout == 0 {
		connected, err := tserver.DialForever()
		if err != nil {
			return nil, err
		}
		<-connected
		return tserver, nil
	}

	return tserver, tserver.DialTimeout(c.opts.Timeout)
}

func (c *Client) waitDNS() error {
	retry := backoff.NewExponentialBackOff()
	retry.MaxElapsedTime = 365 * 24 * time.Hour
	if c.opts.Timeout != 0 {
		retry.MaxElapsedTime = c.opts.Timeout
	}
	retry.Reset()

	host := c.VirtualHost
	if h, _, err := net.SplitHostPort(c.VirtualHost); err == nil {
		host = h
	}

	c.opts.Log.Debug("waiting until %s is resolvable", host)

	for {
		addrs, err := net.LookupHost(host)
		if err == nil && len(addrs) != 0 {
			c.opts.Log.Debug("resolved %s: %v", host, addrs)
			return nil
		}
		next := retry.NextBackOff()
		if next == backoff.Stop {
			return fmt.Errorf("waiting for %s has timed out after %s", host, retry.MaxElapsedTime)
		}
		c.opts.Log.Debug("looking up %s: err=%s, addrs=%v", host, err, addrs)
		time.Sleep(next)
	}
}
