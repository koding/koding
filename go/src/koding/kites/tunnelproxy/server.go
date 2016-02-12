package tunnelproxy

import (
	"errors"
	"fmt"
	"net"
	"net/http"
	"net/url"
	"strings"

	"koding/artifact"
	"koding/kites/common"
	"koding/kites/kloud/pkg/dnsclient"
	"koding/kites/kloud/utils"

	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/koding/ec2dynamicdata"
	"github.com/koding/kite"
	"github.com/koding/kite/config"
	"github.com/koding/logging"
	"github.com/koding/metrics"
	"github.com/koding/tunnel"
)

func publicIP() (string, error) {
	return ec2dynamicdata.GetMetadata(ec2dynamicdata.PublicIPv4)
}

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

	opts   *ServerOptions
	record *dnsclient.Record
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

	if optsCopy.BaseVirtualHost == "" {
		optsCopy.BaseVirtualHost = optsCopy.HostedZone
	}

	optsCopy.Log.Debug("Server options: %# v", &optsCopy)

	s := &Server{
		Server: server,
		DNS:    dns,
		opts:   &optsCopy,
		record: dnsclient.ParseRecord("", optsCopy.ServerAddr),
	}

	// perform the initial healthcheck during startup
	if err := s.checkDNS(); err != nil {
		s.opts.Log.Critical("%s", err)
	}

	return s, nil
}

// RegisterRequest represents request value for register method.
type RegisterRequest struct {
	// VirtualHost is a URL host requested by a client under which
	// new tunnel should be registered. The URL must be rooted
	// at <username>.<basehost> otherwise request will
	// be rejected.
	VirtualHost string `json:"virtualHost,omitempty"`
}

// RegisterResult represents response value for register method.
type RegisterResult struct {
	VirtualHost string `json:"virtualHost"`
	Secret      string `json:"identifier"`
	Domain      string `json:"domain"`
}

func (s *Server) checkDNS() error {
	domain := s.opts.BaseVirtualHost
	if host, _, err := net.SplitHostPort(domain); err == nil {
		domain = host
	}

	// check Route53 is setup correctly
	r, err := s.DNS.GetAll(domain)
	if err != nil {
		return fmt.Errorf("unable to list records for %q: %s", domain, err)
	}

	records := dnsclient.Records(r)

	serverFilter := &dnsclient.Record{
		Name: domain + ".",
	}

	rec := records.Filter(serverFilter)
	if len(rec) == 0 {
		return fmt.Errorf("no records found for %+v", serverFilter)
	}

	// Check if the tunnelserver has a wildcard domain. E.g. if base host for
	// the tunnelserver is devtunnel.koding.com, then we expect a CNAME
	// \052.devntunnel.koding.com is set to devtunnel.koding.com.
	clientsFilter := &dnsclient.Record{
		Name: "\\052." + domain + ".",
		Type: "CNAME",
	}

	rec = records.Filter(clientsFilter)
	if len(rec) == 0 {
		return fmt.Errorf("no records found for %+v", clientsFilter)
	}

	return nil
}

func (s *Server) HealthCheck(name string) http.HandlerFunc {
	return func(w http.ResponseWriter, _ *http.Request) {
		if err := s.checkDNS(); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		w.Header().Set("Content-Type", "text/plain")
		fmt.Fprintf(w, "%s is running with version: %s", name, artifact.VERSION)
	}
}

func (s *Server) virtualHost(user, virtualHost string) (string, error) {
	vhost := user + "." + s.opts.BaseVirtualHost

	if virtualHost != "" {
		if !strings.HasSuffix(virtualHost, vhost) {
			return "", fmt.Errorf("virtual host %q must be rooted at %q for user %s", virtualHost, vhost, user)
		}

		vhost = virtualHost
	}

	return vhost, nil
}

func (s *Server) domain(vhost string) string {
	if host, _, err := net.SplitHostPort(vhost); err == nil {
		return host
	}
	return vhost
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

	vhost, err := s.virtualHost(r.Username, req.VirtualHost)
	if err != nil {
		return nil, err
	}

	res := &RegisterResult{
		VirtualHost: vhost,
		Domain:      s.domain(vhost),
		Secret:      utils.RandString(32),
	}

	s.opts.Log.Debug("adding vhost=%s with secret=%s", res.VirtualHost, res.Secret)

	s.Server.AddHost(res.VirtualHost, res.Secret)

	s.Server.OnDisconnect(res.Secret, func() error {
		s.opts.Log.Debug("deleting vhost=%s and domain=%s", res.VirtualHost, res.Domain)
		s.Server.DeleteHost(res.VirtualHost)
		return nil
	})

	return res, nil
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
	k.HandleHTTPFunc("/healthCheck", s.HealthCheck(name))
	k.HandleHTTPFunc("/version", artifact.VersionHandler())
	k.HandleHTTP("/{rest:.*}", forward("/klient", s.Server))

	if s.opts.RegisterURL == nil {
		s.opts.RegisterURL = k.RegisterURL(false)
	}

	if err := k.RegisterForever(s.opts.RegisterURL); err != nil {
		return nil, err
	}

	return k, nil
}

func forward(path string, handler http.Handler) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		r.URL.Path = strings.TrimPrefix(r.URL.Path, path)
		handler.ServeHTTP(w, r)
	}
}
