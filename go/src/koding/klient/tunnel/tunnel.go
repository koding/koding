// Package tunnel is responsible of setting up and connecting to a tunnel
// server.
package tunnel

import (
	"errors"
	"net"
	"net/url"
	"strings"
	"sync"
	"time"

	"koding/kites/tunnelproxy"
	"koding/klient/info/publicip"
	"koding/klient/vagrant"

	"github.com/boltdb/bolt"
	"github.com/koding/kite"
	"github.com/koding/kite/config"
)

var (
	// ErrKeyNotFound
	ErrKeyNotFound = errors.New("key not found")

	// ErrNoDatabase
	ErrNoDatabase = errors.New("local database is not available")
)

// Tunnel
type Tunnel struct {
	db     *Storage
	opts   *Options
	client *tunnelproxy.Client

	// Cached routes, in case host kite goes down.
	mu    sync.Mutex // protects ports
	ports []*vagrant.ForwardedPort

	// Used to wait for first successful
	// tunnel server registration.
	register sync.WaitGroup
	once     sync.Once
}

// Options
type Options struct {
	TunnelName    string        `json:"tunnelName,omitempty"`
	TunnelKiteURL string        `json:"tunnelKiteURL,omitempty"`
	LocalAddr     string        `json:"localAddr,omitempty"`
	VirtualHost   string        `json:"virtualHost,omitempty"`
	Timeout       time.Duration `json:"timeout,omitempty"`
	PublicIP      net.IP        `jsob:"publicIP,omitempty"`

	// IP reachability test cache
	LastAddr      string `json:"lastAddr,omitempty"`
	LastReachable bool   `json:"lastReachable,omitempty"`

	DB     *bolt.DB       `json:"-"`
	Log    kite.Logger    `json:"-"`
	Config *config.Config `json:"-"`
	Debug  bool           `json:"-"`
}

// updateEmpty overwrites each zero-value field of opts with defaults (merge-in).
func (opts *Options) updateEmpty(defaults *Options) {
	if opts.TunnelName == "" {
		opts.TunnelName = defaults.TunnelName
	}

	if opts.TunnelKiteURL == "" {
		opts.TunnelKiteURL = defaults.TunnelKiteURL
	}

	if opts.LocalAddr == "" {
		opts.LocalAddr = defaults.LocalAddr
	}

	if opts.VirtualHost == "" {
		opts.VirtualHost = defaults.VirtualHost
	}

	if opts.Timeout == 0 {
		opts.Timeout = defaults.Timeout
	}

	if opts.LastAddr == "" {
		opts.LastAddr = defaults.LastAddr
	}

	if !opts.LastReachable {
		opts.LastReachable = defaults.LastReachable
	}

	if opts.DB == nil {
		opts.DB = defaults.DB
	}

	if opts.Log == nil {
		opts.Log = defaults.Log
	}

	if opts.Config == nil {
		opts.Config = defaults.Config
	}

	if !opts.Debug {
		opts.Debug = defaults.Debug
	}

	if opts.PublicIP == nil {
		opts.PublicIP = defaults.PublicIP
	}

	// set defaults
	if opts.Timeout == 0 {
		opts.Timeout = 5 * time.Minute
	}
}

func (opts *Options) copy() *Options {
	optsCopy := *opts

	if opts.Config != nil {
		optsCopy.Config = opts.Config.Copy()
	}

	return &optsCopy
}

// New
func New(opts *Options) *Tunnel {
	optsCopy := *opts

	t := &Tunnel{
		db:   NewStorage(optsCopy.DB),
		opts: &optsCopy,
	}

	t.register.Add(1)

	return t
}

func (t *Tunnel) clientOptions() *tunnelproxy.ClientOptions {
	return &tunnelproxy.ClientOptions{
		TunnelName:      t.opts.TunnelName,
		TunnelKiteURL:   t.opts.TunnelKiteURL,
		LastVirtualHost: t.opts.VirtualHost,
		LocalAddr:       t.opts.LocalAddr,
		LocalRoutes:     t.localRoute(),
		Config:          t.opts.Config,
		Timeout:         t.opts.Timeout,
		OnRegister:      t.updateOptions,
		Debug:           t.opts.Debug,
	}
}

func (t *Tunnel) updateOptions(reg *tunnelproxy.RegisterResult) {
	t.opts.VirtualHost = reg.VirtualHost
	t.opts.TunnelName = guessTunnelName(reg.VirtualHost)

	if err := t.db.SetOptions(t.opts); err != nil {
		t.opts.Log.Warning("tunnel: unable to update options: %s", err)
	}

	t.once.Do(t.register.Done)
}

// buildOptions finalizes build of tunnel options; the contructed options
func (t *Tunnel) buildOptions(final *Options) {
	t.opts.updateEmpty(final)

	t.opts.Log.Debug("buildOptions: final=%+v", t.opts)

	storageOpts, err := t.db.Options()
	if err != nil {
		t.opts.Log.Warning("tunnel: unable to read options: %s", err)
	} else {
		t.opts.updateEmpty(storageOpts)

		t.opts.Log.Debug("buildOptions: storage=%+v, built=%+v", storageOpts, t.opts)
	}

	if err = t.db.SetOptions(t.opts); err != nil {
		t.opts.Log.Warning("tunnel: unable to update options: %s", err)
	}
}

// Start setups the client and connects to a tunnel server based on the given
// configuration. It's non blocking and should be called only once.
func (t *Tunnel) Start(opts *Options, registerURL *url.URL) (*url.URL, error) {
	t.buildOptions(opts)

	if t.opts.LastAddr != registerURL.Host {
		t.opts.Log.Info("testing whether %q address is reachable...", registerURL.Host)

		ok, err := publicip.IsReachableRetry(registerURL.Host, 10, 5*time.Second, t.opts.Log)
		if err != nil {
			t.opts.Log.Warning("tunnel: unable to test %q: %s", registerURL.Host, err)
			return registerURL, nil
		}

		t.opts.LastAddr = registerURL.Host
		t.opts.LastReachable = ok

		if err := t.db.SetOptions(t.opts); err != nil {
			t.opts.Log.Warning("tunnel: unable to update options: %s", err)
		}
	}

	if t.opts.LastReachable {
		return registerURL, nil
	}

	clientOpts := t.clientOptions()

	t.opts.Log.Debug("starting tunnel client")
	t.opts.Log.Debug("tunnel.Options=%+v", opts)
	t.opts.Log.Debug("tunnelproxy.ClientOptions=%+v", clientOpts)

	client, err := tunnelproxy.NewClient(clientOpts)
	if err != nil {
		return nil, err
	}

	t.client = client
	t.client.Start()
	t.register.Wait()

	u := *registerURL
	u.Host = t.opts.VirtualHost
	u.Path = "/klient/kite"

	t.opts.Log.Info("tunnel: connected as %q", u.Host)

	return &u, nil
}

func guessTunnelName(vhost string) string {
	// If vhost is <tunnelName>.<user>.koding.me return the
	// <tunnelName> part (production environment).
	//
	// Example: 62ee1f899a4e.rafal.koding.me
	i := strings.LastIndex(vhost, ".koding.me")
	if i != -1 {
		i = strings.LastIndex(vhost[:i], ".")
		if i != -1 {
			return vhost[:i]
		}
	}

	// If vhost is <tunnelName>.<customBaseVirtualHost> return the
	// <tunnelName> part (development environment).
	//
	// Example: macbook.rafal.t.dev.koding.io:8081
	if strings.Count(vhost, ".") > 1 {
		return vhost[:strings.IndexRune(vhost, '.')]
	}

	return ""
}
