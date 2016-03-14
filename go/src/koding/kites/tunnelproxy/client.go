package tunnelproxy

import (
	"errors"
	"fmt"
	"net"
	"strconv"
	"sync"
	"time"

	"koding/kites/common"
	"koding/klient/protocol"

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

var (
	defaultMaxRegisterRetry = 7
	defaultTimeout          = 30 * time.Second
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

	// OnRegisterServices, when non-nil, is called each time client successfully
	// registers a service to a tunnel server kite.
	OnRegisterServices func(*RegisterServicesResult)

	// MaxRegisterRetry tells at most how many times we should retry connecting
	// to cached tunnel server address before giving up and falling back to
	// global kite URL.
	//
	// If zero, default value of 7 is used.
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

	stateChanges chan *tunnel.ClientStateChange
	regserv      chan map[string]*Tunnel
	services     map[string]*Service // maps service name to a service
	routes       map[int]string      // maps tcp tunnel remote port to local addr
	ident        string              // TODO: use c.connected when tryRegister is moved to eventloop
	mu           sync.Mutex          // protets ident, services and routes
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
		stateChanges:  make(chan *tunnel.ClientStateChange, 128),
		regserv:       make(chan map[string]*Tunnel, 1),
		services:      make(map[string]*Service),
		routes:        make(map[int]string),
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
		FetchLocalAddr:  c.fetchLocalAddr,
		LocalAddr:       c.opts.LocalAddr,
		Debug:           c.opts.Debug,
		Log:             c.opts.Log.New("transport"),
		StateChanges:    c.stateChanges,
	}

	client, err := tunnel.NewClient(cfg)
	if err != nil {
		return nil, err
	}

	c.client = client

	return c, nil
}

func (c *Client) Start() {
	go c.eventloop()
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

// RestoreServices
func (c *Client) RestoreServices(services Services) error {
	if len(services) == 0 {
		return nil // early return for nop ops
	}

	regserv := make(map[string]*Tunnel, len(services))

	for name, srv := range services {
		_, _, err := splitHostPort(srv.LocalAddr)
		if err != nil {
			return fmt.Errorf("invalid local address for %q service: %s", name, err)
		}

		_, remotePort, err := splitHostPort(srv.RemoteAddr)
		if err != nil {
			return fmt.Errorf("invalid remote address for %q service: %s", name, err)
		}

		regserv[name] = &Tunnel{
			Port:    remotePort,
			Restore: true,
		}
	}

	c.mu.Lock()
	for name, srv := range services {
		// Do not set the RemoteAddr - we have no guarantee it'll be restored.
		// If client was disconnected for longer period and other client
		// took that port (unlikely, but possible), we're going to be
		// assigned a different port.
		c.services[name] = &Service{
			LocalAddr: srv.LocalAddr,
		}
	}
	c.mu.Unlock()

	c.regserv <- regserv

	return nil
}

// RegisterService
func (c *Client) RegisterService(name, localAddr string) error {
	if _, _, err := splitHostPort(localAddr); err != nil {
		return fmt.Errorf("invalid local address for %q service: %s", name, err)
	}

	c.mu.Lock()
	c.services[name] = &Service{
		LocalAddr: localAddr,
	}
	c.mu.Unlock()

	c.regserv <- map[string]*Tunnel{name: {}}

	return nil
}

// TODO(rjeczalik): refactor event handlers into separate methods
func (c *Client) eventloop() {
	var (
		handlePending chan struct{}
		ident         string
		pending       = make(map[string]*Tunnel)
		backoff       = backoff.NewExponentialBackOff()
	)

	backoff.MaxElapsedTime = 365 * 24 * time.Hour

	retry := func() {
		time.Sleep(backoff.NextBackOff())

		select {
		case handlePending <- struct{}{}:
		default:
		}
	}

	for {
		select {
		case ch := <-c.stateChanges:
			c.opts.Log.Debug("handling transition: %s", ch)

			switch ch.Current {
			case tunnel.ClientConnected:
				// If we were disconnected and connected again, we need
				// to restore already registered services.
				//
				// A registered service is the one present in c.services
				// map but not is not pending.
				c.mu.Lock()
				for name, srv := range c.services {
					if _, ok := pending[name]; ok {
						continue
					}
					if srv.RemoteAddr == "" {
						c.opts.Log.Debug("%s: service %+v has no remote addr but is not pending", name, srv)
						continue
					}
					// checks in RegisterService/RestoreServices guarantee
					// the RemoteAddr is correctly formatted
					_, remotePort, _ := splitHostPort(srv.RemoteAddr)

					pending[name] = &Tunnel{
						Port:    remotePort,
						Restore: true,
					}
				}

				ident = c.ident

				c.mu.Unlock()

				// when connected, start registering services
				handlePending = make(chan struct{}, 1)
				handlePending <- struct{}{}
				backoff.Reset()
			case tunnel.ClientDisconnected, tunnel.ClientClosed:
				// all TCP tunnels got invalidated, clear routes until
				// we connect again and restore them
				c.mu.Lock()
				c.routes = make(map[int]string)
				c.mu.Unlock()

				handlePending = nil
			}

		case services := <-c.regserv:
			if len(services) == 0 {
				break
			}

			c.opts.Log.Debug("handling service registration request: %+v", services)

			for name, tun := range services {
				pending[name] = tun
			}

			select {
			case handlePending <- struct{}{}:
				backoff.Reset()
			default:
			}

		case <-handlePending:
			if len(pending) == 0 {
				break
			}

			req := &RegisterServicesRequest{
				Ident:    ident,
				Services: pending,
			}

			c.opts.Log.Debug("handling service registration: %+v", pending)

			client, err := c.connect()
			if err != nil {
				c.opts.Log.Error("failure connecting to tunnel server: %s", err)
				go retry()
				break
			}

			r, err := client.TellWithTimeout("registerServices", c.opts.timeout(), req)
			if err != nil {
				c.opts.Log.Error("failure calling registerServices: %s", err)
				go retry()
				break
			}

			var resp RegisterServicesResult
			if err = r.Unmarshal(&resp); err != nil {
				c.opts.Log.Error("failure calling registerServices: %s", err)
				go retry()
				break
			}

			if c.opts.OnRegisterServices != nil {
				c.opts.OnRegisterServices(&resp)
			}

			requsted := len(pending)

			c.mu.Lock()
			for name, srv := range resp.Services {
				if _, ok := c.services[name]; !ok {
					c.opts.Log.Warning("received unrecognized service %q", name)
					continue
				}

				if srv.Err() != nil {
					continue
				}

				c.services[name].RemoteAddr = net.JoinHostPort(resp.VirtualHost, strconv.Itoa(srv.Port))
				c.routes[srv.Port] = c.services[name].LocalAddr
				delete(pending, name)
			}
			c.mu.Unlock()

			if err := resp.Err(); err != nil {
				c.opts.Log.Error("failed to handle all services, retrying: %s", err)
				go retry()
				break
			}

			if len(resp.Services) != requsted {
				c.opts.Log.Warning("wanted to handle %d services, handled only %d", requsted, len(resp.Services))
				go retry()
			}
		}
	}
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

		// TODO(rjeczalik): remove and use connected field directly
		// when tryRegister is moved to eventloop
		c.mu.Lock()
		c.ident = resp.Ident
		c.mu.Unlock()

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

// TODO(rjeczalik): move tryRegister to eventloop
func (c *Client) tryRegister() error {
	client, err := c.connect()
	if err != nil {
		return c.handleReg(nil, err)
	}
	defer client.Close()

	req := &RegisterRequest{
		TunnelName: c.opts.TunnelName,
	}
	kiteResp, err := client.TellWithTimeout("register", c.opts.timeout(), req)
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

func (c *Client) fetchLocalAddr(port int) (string, error) {
	c.mu.Lock()
	addr, ok := c.routes[port]
	c.mu.Unlock()

	if !ok {
		return "", fmt.Errorf("no service route found for %d port", port)
	}

	return addr, nil
}

func (c *Client) connect() (*kite.Client, error) {
	client := c.kite.NewClient(c.tunnelKiteURL)
	client.Auth = &kite.Auth{
		Type: "kiteKey",
		Key:  c.opts.Config.KiteKey,
	}

	if err := client.DialTimeout(c.opts.timeout()); err != nil {
		return nil, fmt.Errorf("dial failed: %s", err)
	}

	return client, nil
}
