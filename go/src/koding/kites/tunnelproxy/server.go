package tunnelproxy

import (
	"errors"
	"fmt"
	"net"
	"net/http"
	"net/url"
	"sort"
	"strconv"
	"strings"
	"sync"

	"koding/artifact"
	"koding/kites/common"
	"koding/kites/kloud/pkg/dnsclient"
	"koding/kites/kloud/utils"

	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/hashicorp/go-multierror"
	"github.com/koding/kite"
	"github.com/koding/kite/config"
	"github.com/koding/logging"
	"github.com/koding/metrics"
	"github.com/koding/tunnel"
)

type ServerOptions struct {
	// Server config.
	BaseVirtualHost string `json:"baseVirtualHost"`
	HostedZone      string `json:"hostedZone" required:"true"`
	AccessKey       string `json:"accessKey" required:"true"`
	SecretKey       string `json:"secretKey" required:"true"`

	// Server kite config.
	Port        int            `json:"port" required:"true"`
	Region      string         `json:"region" required:"true"`
	Environment string         `json:"environment" required:"true"`
	Config      *config.Config `json:"kiteConfig"`
	RegisterURL *url.URL       `json:"registerURL"`

	ServerAddr string `json:"serverAddr,omitempty"` // public IP
	Debug      bool   `json:"debug,omitempty"`
	Test       bool   `json:"test,omitempty"`

	Log     logging.Logger     `json:"-"`
	Metrics *metrics.DogStatsD `json:"-"`
}

// Server represents tunneling server that handles managing authorization
// of the tunneling sessions for the clients.
type Server struct {
	Server *tunnel.Server
	DNS    *dnsclient.Route53

	opts      *ServerOptions
	record    *dnsclient.Record
	callbacks *callbacks

	mu       sync.Mutex // protects services and tunnels
	services map[int]net.Listener
	tunnels  *Tunnels
}

// NewServer gives new tunneling server for the given options.
func NewServer(opts *ServerOptions) (*Server, error) {
	optsCopy := *opts

	if optsCopy.ServerAddr == "" {
		ip, err := publicIP()
		if err != nil {
			return nil, err
		}
		optsCopy.ServerAddr = ip
	}

	if optsCopy.Log == nil {
		optsCopy.Log = common.NewLogger("tunnelserver", optsCopy.Debug)
	}

	optsCopy.Log.Debug("Initial server options: %# v", &optsCopy)

	if optsCopy.BaseVirtualHost == "" {
		optsCopy.BaseVirtualHost = optsCopy.HostedZone
	}

	optsCopy.BaseVirtualHost = customPort(optsCopy.BaseVirtualHost, opts.Port, 80, 443)
	optsCopy.ServerAddr = customPort(optsCopy.ServerAddr, opts.Port)

	tunnelCfg := &tunnel.ServerConfig{
		Debug: optsCopy.Debug,
		Log:   optsCopy.Log,
	}
	server, err := tunnel.NewServer(tunnelCfg)
	if err != nil {
		return nil, err
	}

	dnsOpts := &dnsclient.Options{
		Creds:      credentials.NewStaticCredentials(optsCopy.AccessKey, optsCopy.SecretKey, ""),
		HostedZone: optsCopy.HostedZone,
		Log:        optsCopy.Log,
		Debug:      optsCopy.Debug,
	}
	dns, err := dnsclient.NewRoute53Client(dnsOpts)
	if err != nil {
		return nil, err
	}

	optsCopy.Log.Debug("Server options: %# v", &optsCopy)

	s := &Server{
		Server:   server,
		DNS:      dns,
		opts:     &optsCopy,
		record:   dnsclient.ParseRecord("", optsCopy.ServerAddr),
		services: make(map[int]net.Listener),
		tunnels:  newTunnels(),
	}

	return s, nil
}

// RegisterRequest represents request value for register method.
type RegisterRequest struct {
	// TunnelName requests name of the tunnel to be a part of assigned
	// virtual host.
	//
	// The upserted vhost has the following format:
	//
	//   <tunnelName>.<username>.<basevirtualhost>
	//
	TunnelName string `json:"tunnelName,omitempty"`

	// Username on behalf which handle the registration request.
	Username string `json:"username,omitempty"`
}

// RegisterResult represents response value for register method.
type RegisterResult struct {
	VirtualHost string `json:"virtualHost"`
	Ident       string `json:"identifier"`
	ServerAddr  string `json:"serverAddr"`
}

// RegisterServicesRequest
type RegisterServicesRequest struct {
	Ident    string             `json:"identifier"`
	Services map[string]*Tunnel `json:"services"`
}

// ServiceList
func (req *RegisterServicesRequest) ServiceList() []*Tunnel {
	var t []*Tunnel

	for name, tun := range req.Services {
		tunCopy := *tun
		tunCopy.Name = name

		t = append(t, &tunCopy)
	}

	sort.Sort(TunnelsByName(t))

	return t
}

// Valid
func (req *RegisterServicesRequest) Valid() error {
	if req.Ident == "" {
		return errors.New("empty identifier")
	}

	if len(req.Services) == 0 {
		return errors.New("empty services")
	}

	return nil
}

// RegisterServicesResult
type RegisterServicesResult struct {
	VirtualHost string             `json:"virtualHost"`
	Services    map[string]*Tunnel `json:"services"`
}

// Err
func (res *RegisterServicesResult) Err() (err error) {
	for _, s := range res.Services {
		if e := s.Err(); e != nil {
			err = multierror.Append(err, e)
		}
	}

	return err
}

func (s *Server) addClient(ident, name, vhost string) {
	s.opts.Log.Debug("%s: adding vhost=%s", ident, vhost)

	s.mu.Lock()
	defer s.mu.Unlock()

	s.tunnels.addClient(ident, name, vhost)
	s.Server.AddHost(vhost, ident)
}

func (s *Server) delClient(ident string) {
	s.mu.Lock()
	defer s.mu.Unlock()

	for name, t := range s.tunnels.m[ident] {
		if name == "" {
			s.opts.Log.Debug("%s: deleting http=%q", ident, t.VirtualHost)

			s.Server.DeleteHost(t.VirtualHost)
			continue
		}

		l, ok := s.services[t.Port]
		if !ok {
			continue
		}

		s.opts.Log.Debug("%s: deleting tcp=%q", ident, l.Addr())

		s.Server.DeleteAddr(l, nil)
		l.Close() // TODO(rjeczalik): add 10m grace period for client reconnections
	}

	s.tunnels.delClient(ident)
}

func (s *Server) addClientService(ident string, tun *Tunnel) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	s.opts.Log.Debug("adding %q client: %+v", ident, tun)

	err := s.tunnels.addClientService(ident, tun)
	if err == errAlreadyExists {
		// Tunnel already exists - try to update its port number to
		// requested number or returned already owned one.
		existingTun := s.tunnels.tunnel(ident, tun.Name)

		if tun.Port == existingTun.Port {
			// Tunnel already exists and has requested port.
			return nil
		}

		if tun.Port == 0 || !tun.Restore {
			// Tunnel already exists, reply with its port number.
			tun.Port = existingTun.Port

			return nil
		}

		l, err := net.Listen("tcp", s.addr(tun.Port))
		if err != nil {
			s.opts.Log.Debug("%s: failed to upgrade port %d -> %d for %q", existingTun.Port, tun.Port, ident)

			// Port is still busy, return existing one.
			tun.Port = existingTun.Port
			tun.Restore = false

			return nil
		}

		// We managed to update tunnel's port number to requested value.
		// Replace the listeners.
		existingL, ok := s.services[existingTun.Port]
		if ok {
			s.opts.Log.Debug("%s: removing listener for %q", ident, existingL.Addr())

			s.Server.DeleteAddr(existingL, nil)
			existingL.Close()
			delete(s.services, existingTun.Port)
		}

		s.services[tun.Port] = l
		s.Server.AddAddr(l, nil, ident)
		existingTun.Port = tun.Port

		return nil
	}

	if err != nil {
		return err
	}

	l, err := net.Listen("tcp", s.addr(tun.Port))
	if err != nil && tun.Port != 0 {
		s.opts.Log.Debug("failed to bind to requested port %d, binding to random one: %s", tun.Port, err)

		l, err = net.Listen("tcp", s.addr(0))
	}
	if err != nil {
		return fmt.Errorf("failed to open tunnel: %s", err)
	}

	s.services[tun.Port] = l
	s.Server.AddAddr(l, nil, ident)
	tun.Port = port(l.Addr().String())

	return nil
}

func (s *Server) delClientService(ident, name string) {
	s.mu.Lock()
	defer s.mu.Unlock()

	existingTun := s.tunnels.tunnel(ident, name)
	if existingTun == nil {
		return
	}

	l, ok := s.services[existingTun.Port]
	delete(s.services, existingTun.Port)
	if !ok {
		return
	}

	s.Server.DeleteAddr(l, nil)
}

func (s *Server) addr(port int) string {
	return net.JoinHostPort(host(s.opts.ServerAddr), strconv.Itoa(port))
}

// RegisterServices
func (s *Server) RegisterServices(r *kite.Request) (interface{}, error) {
	var req RegisterServicesRequest

	if r.Args == nil {
		return nil, errors.New("invalid request")
	}

	if err := r.Args.One().Unmarshal(&req); err != nil {
		return nil, errors.New("invalid request: " + err.Error())
	}

	if err := req.Valid(); err != nil {
		return nil, errors.New("invalid request: " + err.Error())
	}

	var err error
	var ok bool
	services := req.ServiceList()
	res := &RegisterServicesResult{
		VirtualHost: host(s.tunnels.tunnel(req.Ident, "").VirtualHost),
		Services:    make(map[string]*Tunnel, len(services)),
	}
	for _, service := range services {
		e := s.addClientService(req.Ident, service)
		if e != nil {
			service.Error = e.Error()
			err = multierror.Append(err, e)
		} else {
			// If at least one service got successfully set up,
			// we're going to return success. The caller is up
			// to decided whether consider whole request
			// as a success or as a failure and retry.
			ok = true
			service.VirtualHost = res.VirtualHost
		}

		res.Services[service.Name] = service
	}

	if !ok && err != nil {
		return nil, err
	}

	return res, nil
}

func (s *Server) vhost(req *RegisterRequest) string {
	return fmt.Sprintf("%s.%s.%s", req.TunnelName, req.Username, s.opts.BaseVirtualHost)
}

// Register creates a virtual host and DNS record for the user.
func (s *Server) Register(r *kite.Request) (interface{}, error) {
	var req RegisterRequest

	if r.Args != nil {
		err := r.Args.One().Unmarshal(&req)
		if err != nil {
			return nil, errors.New("invalid request: " + err.Error())
		}
	}

	// register requests issued by managed kites always have Username
	// empty
	if req.Username == "" {
		req.Username = r.Username
	}

	// try to always have distinct name for the tunnel, a single user
	// can have more than one tunnel; for tunnels created by kloud
	// the TunnelName is always distinct (= jMachine.Uid), for
	// managed kites we need to generate the name here
	if req.TunnelName == "" {
		req.TunnelName = utils.RandString(12)
	}

	s.opts.Log.Debug("received register request: %# v", &req)

	vhost := s.vhost(&req)

	if err := s.upsert(vhost); err != nil {
		return nil, err
	}

	res := &RegisterResult{
		VirtualHost: vhost,
		ServerAddr:  s.opts.ServerAddr,
		Ident:       utils.RandString(32),
	}

	s.addClient(res.Ident, req.TunnelName, res.VirtualHost)

	s.Server.OnDisconnect(res.Ident, func() error {
		s.delClient(res.Ident)
		return nil
	})

	return res, nil
}

func (s *Server) upsert(vhost string) error {
	rec := *s.record
	rec.Name = vhost

	// Trim port part from s.opts.BaseVirtualHost.
	if host, _, err := net.SplitHostPort(rec.Name); err == nil {
		rec.Name = host
	}

	s.opts.Log.Debug("upserting %# v", rec)

	if host, _, err := net.SplitHostPort(vhost); err == nil {
		rec.Name = host
	}

	return s.DNS.UpsertRecord(&rec)
}

func (s *Server) metricsFunc() kite.HandlerFunc {
	if s.opts.Metrics == nil {
		return nil
	}
	m := s.opts.Metrics
	log := s.opts.Log
	return func(r *kite.Request) (interface{}, error) {
		// Send the metrics concurrently and don't block method handler.
		go func() {
			err := m.Count("callCount", 1, []string{"funcName:" + r.Method}, 1.0)
			if err != nil {
				log.Warning("failed to send metrics for method=%s, user=%s: %s", r.Method, r.Username, err)
			}
		}()
		return true, nil
	}
}

// NewServerKite creates a server kite for the given server.
func NewServerKite(s *Server, name, version string) (*kite.Kite, error) {
	k := kite.New(name, version)

	if s.opts.Config == nil {
		cfg, err := config.Get()
		if err != nil {
			return nil, err
		}
		s.opts.Config = cfg
	}

	if s.opts.Port != 0 {
		s.opts.Config.Port = s.opts.Port
	}
	if s.opts.Region != "" {
		s.opts.Config.Region = s.opts.Region
	}
	if s.opts.Environment != "" {
		s.opts.Config.Environment = s.opts.Environment
	}
	if s.opts.Test {
		s.opts.Config.DisableAuthentication = true
	}
	if s.opts.Debug {
		k.SetLogLevel(kite.DEBUG)
	}

	k.Log = s.opts.Log
	k.Config = s.opts.Config

	if fn := s.metricsFunc(); fn != nil {
		k.PreHandleFunc(fn)
	}

	k.HandleFunc("register", s.Register)
	k.HandleFunc("registerServices", s.RegisterServices)
	k.HandleHTTPFunc("/healthCheck", artifact.HealthCheckHandler(name))
	k.HandleHTTPFunc("/version", artifact.VersionHandler())
	k.HandleHTTP("/{rest:.*}", forward("/klient", s.Server))

	if s.opts.RegisterURL == nil {
		s.opts.RegisterURL = k.RegisterURL(false)
	}

	return k, nil
}

func forward(path string, handler http.Handler) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		r.URL.Path = strings.TrimPrefix(r.URL.Path, path)
		handler.ServeHTTP(w, r)
	}
}
