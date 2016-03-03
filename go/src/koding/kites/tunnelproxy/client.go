package tunnelproxy

import (
	"errors"
	"fmt"
	"time"

	"koding/kites/common"
	"koding/klient/protocol"

	"github.com/koding/kite"
	"github.com/koding/kite/config"
	"github.com/koding/logging"
	"github.com/koding/tunnel"
)

const (
	ClientKiteName    = "tunnelclient"
	ClientKiteVersion = "0.0.1"
)

var (
	defaultMaxRegisterRetry = 3
	defaultTimeout          = 1 * time.Minute
)

// TunnelKiteURLFromEnv gives tunnel server kite URL base on the given
// environment.
func TunnelKiteURLFromEnv(env string) string {
	switch env {
	case "managed", "production":
		return "http://tunnelproxy.koding.com/kite"
	default: // "sandbox", "development"
		return "http://devtunnelproxy.koding.com/kite"
	}
}

// ClientOptions are used to alternate behavior of
type ClientOptions struct {
	// TunnelName is a name for the tunnel to use. Based on this value
	// tunnel server creates virtual host names, which look like:
	//
	//   <TunnelName>.<Username>.<BaseVirtualHost>
	//
	// This field is required.
	TunnelName string

	// TunnelKiteURL is a global tunnel server kite URL.
	//
	// If empty, TunnelKiteURLFromEnv is used instead.
	TunnelKiteURL string

	// LastVirtualHost is saved virtual host from previous connection.
	// When non-empty, it's used for the first register calls.
	LastVirtualHost string

	// OnRegister, when non-nil, is called each time client successfully
	// registers to a tunnel server kite.
	OnRegister func(*RegisterResult)

	// MaxRegisterRetry tells at most how many times we should retry connecting
	// to cached tunnel server address before giving up and falling back to
	// global kite URL.
	//
	// If zero, default value of 5 is used.
	MaxRegisterRetry int

	// Timeout for connecting to tunnel server kite.
	//
	// If zero, default value of 1m s is used.
	Timeout time.Duration

	// LocalAddr is a network address where all HTTP requests are tunneled to.
	//
	// If empty, 127.0.0.1:port is used, when port is the tunnelserver's
	// port on which it received connection.
	LocalAddr string

	Debug  bool           // whether to use debug logging
	Log    logging.Logger // overwrites logger used with custom one
	Config *config.Config // configures kite.Kite to connect to tunnelserver
}

// Valid validates the ClientOptions, returning non-nil error when
// a required field has zero value.
func (opts *ClientOptions) Valid() error {
	if opts.TunnelName == "" {
		return errors.New("TunnelName is missing")
	}

	if opts.Config == nil {
		return errors.New("kite configuration is missing")
	}

	return nil
}

func (opts *ClientOptions) tunnelKiteURL() string {
	if opts.TunnelKiteURL != "" {
		return opts.TunnelKiteURL
	}
	return TunnelKiteURLFromEnv(protocol.Environment)
}

func (opts *ClientOptions) maxRegisterRetry() int {
	if opts.MaxRegisterRetry > 0 {
		return opts.MaxRegisterRetry
	}
	return defaultMaxRegisterRetry
}

func (opts *ClientOptions) timeout() time.Duration {
	if opts.Timeout > 0 {
		return opts.Timeout
	}
	return defaultTimeout
}

// Client extends tunnel.Client with an ability of registering to
// a tunnel server kite.
type Client struct {
	client *tunnel.Client
	kite   *kite.Kite
	opts   *ClientOptions // a copy, mutated by Client

	connected     *RegisterResult
	tunnelKiteURL string
	retry         int
}

// NewClient gives new, unstarted tunnel client for the given options.
func NewClient(opts *ClientOptions) (*Client, error) {
	if err := opts.Valid(); err != nil {
		return nil, err
	}

	optsCopy := *opts
	optsCopy.Config = opts.Config.Copy()

	if optsCopy.Log == nil {
		optsCopy.Log = common.NewLogger("tunnelclient", optsCopy.Debug)
	}

	c := &Client{
		kite:          kite.New(ClientKiteName, ClientKiteVersion),
		opts:          &optsCopy,
		tunnelKiteURL: optsCopy.tunnelKiteURL(),
	}

	// If VirtualHost was configured, try to connect to it first.
	if c.opts.LastVirtualHost != "" {
		c.tunnelKiteURL = fmt.Sprintf("http://%s/kite", c.opts.LastVirtualHost)
		c.connected = &RegisterResult{
			VirtualHost: c.opts.LastVirtualHost,
			ServerAddr:  c.opts.LastVirtualHost,
		}
	}

	c.kite.Config = c.opts.Config

	cfg := &tunnel.ClientConfig{
		FetchIdentifier: c.fetchIdent,
		FetchServerAddr: c.fetchServerAddr,
		LocalAddr:       c.opts.LocalAddr,
		Debug:           c.opts.Debug,
		Log:             c.opts.Log.New("transport"),
	}

	client, err := tunnel.NewClient(cfg)
	if err != nil {
		return nil, err
	}

	c.client = client

	return c, nil
}

func (c *Client) Start() {
	go c.client.Start()
	<-c.client.StartNotify()
}

func (c *Client) Close() (err error) {
	if c.client != nil {
		err = c.client.Close()
	}
	if c.kite != nil {
		c.kite.Close()
	}
	return err
}

// handleReg is a strategy for picking tunnelserver address depending on
// the state of the client, whether we were connected before,
// we know the tunnelserver instance or we exceeded the retries.
//
// TODO(rjeczalik): HTTPS support?
func (c *Client) handleReg(resp *RegisterResult, err error) error {
	if err == nil {
		c.opts.Log.Debug("connected to %q: %+v", c.tunnelKiteURL, resp)

		c.tunnelKiteURL = fmt.Sprintf("http://%s/kite", resp.ServerAddr)
		c.connected = resp
		c.retry = 0

		if c.opts.OnRegister != nil {
			c.opts.OnRegister(resp)
		}

		return nil
	}

	c.opts.Log.Debug("failed connecting to %q: %s", c.tunnelKiteURL, err)

	c.retry++

	// If we exceeded number of max retries or we were not connected before,
	// we use default tunnelserver kite URL.
	if c.connected == nil || c.retry >= c.opts.maxRegisterRetry() {
		c.tunnelKiteURL = c.opts.tunnelKiteURL()
		c.connected = nil
	}

	return err
}

func (c *Client) tryRegister() error {
	client := c.kite.NewClient(c.tunnelKiteURL)
	client.Auth = &kite.Auth{
		Type: "kiteKey",
		Key:  c.opts.Config.KiteKey,
	}

	if err := client.DialTimeout(c.opts.timeout()); err != nil {
		return c.handleReg(nil, err)
	}
	defer client.Close()

	req := &RegisterRequest{
		TunnelName: c.opts.TunnelName,
	}
	kiteResp, err := client.TellWithTimeout("register", c.opts.Timeout, req)
	if err != nil {
		return c.handleReg(nil, err)
	}

	var resp RegisterResult
	if err = kiteResp.Unmarshal(&resp); err != nil {
		return c.handleReg(nil, err)
	}

	return c.handleReg(&resp, nil)
}

// fetchIdent registeres to tunnelserver and gives identifier for the session.
func (c *Client) fetchIdent() (string, error) {
	if err := c.tryRegister(); err != nil {
		return "", err
	}

	return c.connected.Ident, nil
}

// fetchServerAddr assumes we are already registered to tunnelserver via
// the fetchIdent call, so it just returns server address.
func (c *Client) fetchServerAddr() (string, error) {
	if c.connected == nil {
		return "", fmt.Errorf("tunnel %q is not connected", c.opts.LastVirtualHost)
	}
	return c.connected.ServerAddr, nil
}

func (c *Client) connect() (*kite.Client, error) {
	tserver := c.kite.NewClient(c.tunnelKiteURL)
	tserver.Auth = &kite.Auth{
		Type: "kiteKey",
		Key:  c.opts.Config.KiteKey,
	}

	if c.opts.Timeout < 0 {
		connected, err := tserver.DialForever()
		if err != nil {
			return nil, err
		}
		<-connected
		return tserver, nil
	}

	return tserver, tserver.DialTimeout(c.opts.Timeout)
}
