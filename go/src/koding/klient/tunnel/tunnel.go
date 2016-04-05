// Package tunnel is responsible of setting up and connecting to a tunnel
// server.
package tunnel

import (
	"net"
	"net/url"
	"strconv"
	"strings"
	"sync"
	"time"

	"koding/kites/tunnelproxy"
	"koding/klient/info/publicip"
	"koding/klient/storage"
	"koding/klient/tunnel/tlsproxy"
	"koding/klient/vagrant"

	"github.com/boltdb/bolt"
	"github.com/koding/kite"
	"github.com/koding/kite/config"
	"github.com/koding/tunnel"
)

type Tunnel struct {
	db     *Storage
	client *tunnelproxy.Client

	// Cached routes, in case host kite goes down.
	mu       sync.Mutex // protects ports, opts and services
	ports    []*vagrant.ForwardedPort
	opts     *Options
	services tunnelproxy.Services

	// Used to wait for first successful tunnel server registration.
	register     sync.WaitGroup
	once         sync.Once
	onceServices sync.Once

	state        tunnel.ClientState
	stateChanges chan *tunnel.ClientStateChange
	isVagrant    bool

	proxy *tlsproxy.Proxy
}

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

	Debug   bool `json:"-"`
	NoProxy bool `json:"-"`
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

func New(opts *Options) (*Tunnel, error) {
	optsCopy := *opts

	target := net.JoinHostPort("127.0.0.1", strconv.Itoa(optsCopy.Config.Port))

	t := &Tunnel{
		db:           NewStorage(optsCopy.DB),
		opts:         &optsCopy,
		stateChanges: make(chan *tunnel.ClientStateChange),
	}

	if !optsCopy.NoProxy {
		optsCopy.Log.Debug("starting tlsproxy for %q target", target)

		p, err := tlsproxy.NewProxy("0.0.0.0:56790", target)
		if err != nil {
			return nil, err
		}

		t.proxy = p
	}

	go t.eventloop()

	t.register.Add(1)

	return t, nil
}

func (t *Tunnel) clientOptions() *tunnelproxy.ClientOptions {
	return &tunnelproxy.ClientOptions{
		TunnelName:         t.opts.TunnelName,
		TunnelKiteURL:      t.opts.TunnelKiteURL,
		LastVirtualHost:    t.opts.VirtualHost,
		LocalAddr:          t.opts.LocalAddr,
		Services:           t.buildServices(),
		Config:             t.opts.Config,
		Timeout:            t.opts.Timeout,
		OnRegister:         t.updateOptions,
		OnRegisterServices: t.updateServices,
		PublicIP:           t.opts.PublicIP.String(),
		Debug:              t.opts.Debug,
		NoProxy:            t.opts.NoProxy,
		StateChanges:       t.stateChanges,
	}
}

func (t *Tunnel) eventloop() {
	for ch := range t.stateChanges {
		t.mu.Lock()
		t.state = ch.Current
		t.mu.Unlock()
	}
}

func (t *Tunnel) updateOptions(reg *tunnelproxy.RegisterResult) {
	t.mu.Lock()
	t.opts.VirtualHost = reg.VirtualHost
	t.opts.TunnelName = guessTunnelName(reg.VirtualHost)

	// if we're a vagrant vm, update forwarded ports
	if t.isVagrant {
		ports, err := t.forwardedPorts()
		if err == nil {
			t.ports = ports
		} else {
			t.opts.Log.Error("failed to update forwarded port list: %s", err)

			t.ports = nil
		}
	}

	t.onceServices.Do(t.initServices)
	t.restoreServices()
	t.mu.Unlock()

	if err := t.db.SetOptions(t.opts); err != nil {
		t.opts.Log.Warning("tunnel: unable to update options: %s", err)
	}

	t.once.Do(t.register.Done)
}

func (t *Tunnel) initServices() {
	if !t.isVagrant {
		return // no ssh service for non-vagrant kites (e.g. managed ones)
	}

	s, err := t.db.Services()
	if err == storage.ErrKeyNotFound {
		s = tunnelproxy.Services{
			"ssh": &tunnelproxy.Service{
				LocalAddr: "127.0.0.1:22",
			},
		}

		err = t.db.SetServices(s)
	}

	if err != nil {
		t.opts.Log.Warning("tunnel: unable to init services: %s", err)
		return
	}
}

func (t *Tunnel) updateServices(reg *tunnelproxy.RegisterServicesResult) {
	t.mu.Lock()
	defer t.mu.Unlock()

	if err := reg.Err(); err != nil {
		t.opts.Log.Debug("failed to register all of the services: %s", err)
	}

	var updated int
	for name, tun := range reg.Services {
		if tun.Err() != nil {
			continue
		}

		service, ok := t.services[name]
		if !ok {
			service = &tunnelproxy.Service{}
			t.services[name] = service
		}

		service.RemoteAddr = net.JoinHostPort(host(tun.VirtualHost), strconv.Itoa(tun.Port))

		updated++
	}

	// ignore nop updates
	if updated != 0 {
		if err := t.db.SetServices(t.services); err != nil {
			t.opts.Log.Warning("tunnel: unable to update services: %s", err)
		}
	}
}

func (t *Tunnel) restoreServices() {
	services, err := t.db.Services()
	if err != nil {
		t.opts.Log.Warning("tunnel: unable to read services: %s", err)
		return
	}

	// update forwarded ports if there are any
	if len(t.ports) != 0 {
		t.opts.Log.Debug("updating forwarded ports for services: %+v", t.ports)

		for _, s := range services {
			_, localPort, err := splitHostPort(s.RemoteAddr)
			if err != nil || localPort <= 0 {
				t.opts.Log.Warning("tunne: skipping %+v service, missing local address: %s", s, err)
				continue
			}

			t.opts.Log.Debug("updating forwarded ports for %q service", s.Name)

			for _, p := range t.ports {
				if p.GuestPort == localPort {
					t.opts.Log.Debug("found forwarded port for %q service: %+v", s.Name, p)

					s.ForwardedPort = p.HostPort
					break
				}
			}
		}
	}

	// TODO(rjeczalik): add vagrant.forwardPort to host klient and call
	// it for each services that does not have forwarded port; required
	// in order to add tunnel.add

	if err := t.client.RestoreServices(services); err != nil {
		t.opts.Log.Error("tunnel: unable to restore %d services: %s", len(services), err)
	}

	t.services = services

	if err := t.db.SetServices(services); err != nil {
		t.opts.Log.Warning("tunnel: unable to update services: %s", err)
	}
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

	clientOpts := t.clientOptions()

	if t.opts.LastReachable && !t.isVagrant {
		return registerURL, nil
	}

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

func host(hostport string) string {
	if host, _, err := net.SplitHostPort(hostport); err == nil {
		return host
	}

	return hostport
}

func splitHostPort(addr string) (string, int, error) {
	host, port, err := net.SplitHostPort(addr)
	if err != nil {
		return "", 0, err
	}

	n, err := strconv.ParseUint(port, 10, 16)
	if err != nil {
		return "", 0, err
	}

	return host, int(n), nil
}

func guessTunnelName(vhost string) string {
	// If vhost is <tunnelName>.<BaseVirtualHost> return the
	// <tunnelName> part (development environment).
	//
	// Example: macbook.rafal.t.dev.koding.io:8081
	if strings.Count(vhost, ".") > 1 {
		return vhost[:strings.IndexRune(vhost, '.')]
	}

	return ""
}
