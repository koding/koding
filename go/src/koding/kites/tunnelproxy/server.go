package tunnelproxy

import (
	"errors"
	"fmt"
	"net"
	"net/http"
	"net/url"
	"strconv"
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

// customPort adds a port part to the given address. If port is a zero-value,
// or the addr parameter already has a port set - this function is a nop.
func customPort(addr string, port int) string {
	if addr == "" {
		return ""
	}

	if port == 0 {
		return addr
	}

	_, _, err := net.SplitHostPort(addr)
	if err != nil {
		return net.JoinHostPort(addr, strconv.Itoa(port))
	}

	return addr
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

	optsCopy.BaseVirtualHost = customPort(optsCopy.BaseVirtualHost, opts.Port)
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
	Username string
}

// RegisterResult represents response value for register method.
type RegisterResult struct {
	VirtualHost string `json:"virtualHost"`
	Ident       string `json:"identifier"`
	ServerAddr  string `json:"serverAddr"`
}

func (s *Server) vhost(req *RegisterRequest) string {
	host := fmt.Sprintf("%s.%s.%s", req.TunnelName, req.Username, s.opts.BaseVirtualHost)

	// Adjust port if tunnel server is running on different port than
	// default HTTP/HTTPS one. Used mainly for development environment.
	if _, port, err := net.SplitHostPort(s.opts.ServerAddr); err == nil {
		host = host + ":" + port
	}

	return host
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

	vhost := s.vhost(&req)

	if err := s.upsert(vhost); err != nil {
		return nil, err
	}

	res := &RegisterResult{
		VirtualHost: vhost,
		ServerAddr:  s.opts.ServerAddr,
		Ident:       utils.RandString(32),
	}

	s.opts.Log.Debug("adding vhost=%s with secret=%s", res.VirtualHost, res.Ident)
	s.Server.AddHost(res.VirtualHost, res.Ident)

	s.Server.OnDisconnect(res.Ident, func() error {
		s.opts.Log.Debug("deleting vhost=%s", res.VirtualHost)
		s.Server.DeleteHost(res.VirtualHost)
		return nil
	})

	return res, nil
}

func (s *Server) upsert(vhost string) error {
	rec := *s.record
	rec.Name = vhost

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
