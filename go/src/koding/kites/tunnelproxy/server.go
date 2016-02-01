package tunnelproxy

import (
	"net"
	"net/url"

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

// TODO(rjecalik): improve dnsclient, Route53 does not handle concurrent
// request, the caller must queue them.

// publicIP
func publicIP() (string, error) {
	return ec2dynamicdata.GetMetadata(ec2dynamicdata.PublicIPv4)
}

// ServerConfig
type ServerOptions struct {
	// Server config.
	BaseVirtualHost string `json:"baseVirtualHost" required:"true"`
	HostedZone      string `json:"hostedZone" required:"true"`
	AccessKey       string `json:"accessKey" required:"true"`
	SecretKey       string `json:"secretKey" required:"true"`

	// Server kite config.
	Port        int            `json:"port"`
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

// Server
type Server struct {
	Server *tunnel.Server
	DNS    *dnsclient.Route53

	opts   *ServerOptions
	record *dnsclient.Record
}

// NewServer
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
		// SyncTimeout: 1 * time.Minute,
	}
	dns, err := dnsclient.NewRoute53Client(dnsOpts)
	if err != nil {
		return nil, err
	}

	if optsCopy.BaseVirtualHost == "" {
		optsCopy.BaseVirtualHost = dns.HostedZone()
	}

	return &Server{
		Server: server,
		DNS:    dns,
		opts:   &optsCopy,
		record: dnsclient.ParseRecord("", optsCopy.ServerAddr),
	}, nil
}

// RegisterResult
type RegisterResult struct {
	VirtualHost string `virtualHost"`
	Domain      string `json:"domain"`
	Secret      string `json:"secret"`
}

func (s *Server) virtualHost(username string) string {
	return username + "." + s.opts.BaseVirtualHost
}

func (s *Server) domain(username string) string {
	if host, _, err := net.SplitHostPort(s.opts.BaseVirtualHost); err == nil {
		return username + "." + host
	}
	return username + "." + s.opts.BaseVirtualHost
}

// Register
func (s *Server) Register(r *kite.Request) (interface{}, error) {
	res := &RegisterResult{
		VirtualHost: s.virtualHost(r.Username),
		Domain:      s.domain(r.Username),
		Secret:      utils.RandString(32),
	}

	s.opts.Log.Debug("upserting domain: %s", res.Domain)

	if err := s.upsert(res.Domain); err != nil {
		return nil, err
	}

	s.opts.Log.Debug("adding vhost=%s with secret=%s", res.VirtualHost, res.Secret)

	s.Server.AddHost(res.VirtualHost, res.Secret)

	s.Server.OnDisconnect(res.Secret, func() error {
		s.opts.Log.Debug("deleting vhost=%s and domain=%s", res.VirtualHost, res.Domain)
		s.Server.DeleteHost(res.VirtualHost)
		// TODO(rjeczalik): Route53 does not handle concurrent requests
		return s.DNS.Delete(res.Domain)
	})

	return res, nil
}

func (s *Server) upsert(domain string) error {
	// TODO(rjeczalik): Route53 does not handle concurrent requests
	rec := *s.record
	rec.Name = domain
	return s.DNS.UpsertRecord(&rec)
}

// metricsFunc
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

// NewServerKite
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
	k.HandleHTTPFunc("/healthCheck", artifact.HealthCheckHandler(name))
	k.HandleHTTPFunc("/version", artifact.VersionHandler())
	k.HandleHTTP("/{rest:.*}", s.Server)

	if s.opts.RegisterURL == nil {
		s.opts.RegisterURL = k.RegisterURL(false)
	}

	if err := k.RegisterForever(s.opts.RegisterURL); err != nil {
		return nil, err
	}

	return k, nil
}
