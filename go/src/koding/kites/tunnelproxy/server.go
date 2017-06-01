package tunnelproxy

import (
	"crypto/tls"
	"encoding/json"
	"errors"
	"fmt"
	"net"
	"net/http"
	"net/url"
	"os"
	"os/user"
	"sort"
	"strconv"
	"strings"
	"sync"
	"time"

	"koding/artifact"
	"koding/kites/common"
	konfig "koding/kites/config"
	"koding/kites/kloud/pkg/dnsclient"
	"koding/kites/kloud/utils"
	"koding/kites/metrics"
	"koding/tools/util"

	dogstatsd "github.com/DataDog/datadog-go/statsd"
	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/gorilla/mux"
	"github.com/hashicorp/go-multierror"
	"github.com/koding/kite"
	"github.com/koding/logging"
	"github.com/koding/tunnel"
)

type ServerOptions struct {
	// Server config.
	BaseVirtualHost string `json:"baseVirtualHost"`
	HostedZone      string `json:"hostedZone"`
	AccessKey       string `json:"accessKey"`
	SecretKey       string `json:"secretKey"`

	// Server kite config.
	Port        int    `json:"port" required:"true"`
	Region      string `json:"region" required:"true"`
	Environment string `json:"environment" required:"true"`
	RegisterURL string `json:"registerURL"`
	KontrolURL  string `json:"kontrolURL"`

	TCPRangeFrom int    `json:"tcpRangeFrom,omitempty"`
	TCPRangeTo   int    `json:"tcpRangeTo,omitempty"`
	ServerAddr   string `json:"serverAddr,omitempty"` // public IP
	Debug        bool   `json:"debug,omitempty"`
	Test         bool   `json:"test,omitempty"`
	NoCNAME      bool   `json:"noCNAME,omitempty"`

	Log     logging.Logger    `json:"-"`
	Metrics *dogstatsd.Client `json:"-"`
}

func (opts *ServerOptions) registerURL() string {
	if opts.RegisterURL != "" {
		return opts.RegisterURL
	}

	return konfig.Builtin.Endpoints.TunnelServer.Public.String()
}

func (opts *ServerOptions) kontrolURL() string {
	if opts.KontrolURL != "" {
		return opts.KontrolURL
	}

	return konfig.Builtin.KontrolPublic().String()
}

// Server represents tunneling server that handles managing authorization
// of the tunneling sessions for the clients.
type Server struct {
	Server *tunnel.Server
	DNS    *dnsclient.Route53

	opts      *ServerOptions
	record    *dnsclient.Record
	callbacks *callbacks
	privateIP string

	mu       sync.Mutex        // protects idents, services and tunnels
	idents   map[string]string // maps vhost to ident
	services map[int]net.Listener
	tunnels  *Tunnels

	last   int        // last random port when TCP range is set
	lastMu sync.Mutex // protects last
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

	if optsCopy.Metrics == nil {
		optsCopy.Metrics = common.MustInitMetrics("tunnelproxy")
	}

	if optsCopy.Log == nil {
		optsCopy.Log = logging.NewCustom("tunnelserver", optsCopy.Debug)
	}

	optsCopy.Log.Debug("Initial server options: %# v", &optsCopy)

	if optsCopy.BaseVirtualHost == "" {
		optsCopy.BaseVirtualHost = optsCopy.HostedZone
	}

	if optsCopy.BaseVirtualHost == "" {
		return nil, errors.New("either BaseVirtualHost or HostedZone parameter is required to be non-empty")
	}

	optsCopy.BaseVirtualHost = customPort(optsCopy.BaseVirtualHost, opts.Port, 80, 443)
	optsCopy.ServerAddr = customPort(optsCopy.ServerAddr, opts.Port)

	if optsCopy.TCPRangeFrom == 0 {
		optsCopy.TCPRangeFrom = 20000
	}

	if optsCopy.TCPRangeTo == 0 {
		optsCopy.TCPRangeTo = 50000
	}

	tunnelCfg := &tunnel.ServerConfig{
		Debug: optsCopy.Debug,
		Log:   optsCopy.Log,
	}
	server, err := tunnel.NewServer(tunnelCfg)
	if err != nil {
		return nil, err
	}

	if optsCopy.NoCNAME && (optsCopy.AccessKey == "" || optsCopy.SecretKey == "") {
		return nil, errors.New("no valid Route53 configuration found")
	}

	var dns *dnsclient.Route53
	if optsCopy.AccessKey != "" && optsCopy.SecretKey != "" {
		dnsOpts := &dnsclient.Options{
			Creds:      credentials.NewStaticCredentials(optsCopy.AccessKey, optsCopy.SecretKey, ""),
			HostedZone: optsCopy.HostedZone,
			Log:        optsCopy.Log,
			Debug:      optsCopy.Debug,
		}
		dns, err = dnsclient.NewRoute53Client(dnsOpts)
		if err != nil {
			return nil, err
		}
	}

	// Inserts DNS records for the tunnelserver. Host-routing requires an A record pointing
	// to the tunnelserver and a wildcard CNAME record pointing to that A record.
	// In other words if tunnel.example.com resolves to the tunnelserver, then
	// *.tunnel.example.com must also resolve to the very same tunnelserver instance.
	//
	// If there are not route53 credentials passed, we assume the DNS records are
	// taken care externally.
	if !optsCopy.NoCNAME && dns != nil {
		id, err := instanceID()
		if err != nil {
			if optsCopy.Test {
				username := os.Getenv("USER")
				if u, err := user.Current(); err == nil {
					username = u.Username
				}

				id = "koding-" + username
			}
		}

		if id != "" {
			optsCopy.BaseVirtualHost = strings.TrimPrefix(id, "i-") + "." + optsCopy.BaseVirtualHost
		}

		ip := host(optsCopy.ServerAddr)
		base := host(optsCopy.BaseVirtualHost)

		tunnelRec := &dnsclient.Record{
			Name: base,
			IP:   ip,
			Type: "A",
			TTL:  300,
		}

		allRec := &dnsclient.Record{
			Name: "\\052." + base,
			IP:   base,
			Type: "CNAME",
			TTL:  300,
		}

		// TODO(rjeczalik): add retries to pkg/dnsclient (TMS-2052)
		for i := 0; i < 5; i++ {
			if err = dns.UpsertRecords(tunnelRec, allRec); err == nil {
				break
			}

			time.Sleep(time.Duration(i) * time.Second) // linear backoff, overall time: 30s
		}

		if err != nil {
			return nil, err
		}
	}

	optsCopy.Log.Debug("Server options: %# v", &optsCopy)

	s := &Server{
		Server:    server,
		DNS:       dns,
		opts:      &optsCopy,
		privateIP: "0.0.0.0",
		record:    dnsclient.ParseRecord("", optsCopy.ServerAddr),
		idents:    make(map[string]string),
		services:  make(map[int]net.Listener),
		tunnels:   newTunnels(),
	}

	// Do not bind to private address for testing.
	if !s.opts.Test {
		if ip, err := privateIP(); err == nil {
			s.privateIP = ip
		}
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

	// Services forwards tunnel connections to the endpoint on localhost.
	// If both local server of the tunnel and the client are within the
	// same network, all HTTP requests are going to be redirected to
	// use local interfece instead.
	//
	// TODO(rjeczalik): for now Services field is used to register
	// kite and kites services, but it can be also used to register
	// known services upon start, instead of issuing separate
	// RegisterServices call.
	Services map[string]*Tunnel `json:"services,omitempty"` // maps publicIP to local address
}

// RegisterResult represents response value for register method.
type RegisterResult struct {
	VirtualHost string `json:"virtualHost"`
	Ident       string `json:"identifier"`
	ServerAddr  string `json:"serverAddr"`
}

type RegisterServicesRequest struct {
	Ident    string             `json:"identifier"`
	Services map[string]*Tunnel `json:"services"`
}

func toList(services map[string]*Tunnel, vhost string) []*Tunnel {
	var t []*Tunnel

	for name, tun := range services {
		tunCopy := *tun
		tunCopy.Name = strings.ToLower(strings.TrimSpace(name))
		tunCopy.VirtualHost = vhost

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

func (s *Server) addClient(ident, name, vhost string, services map[string]*Tunnel) {
	s.opts.Log.Debug("%s: adding vhost=%s", ident, vhost)

	s.mu.Lock()
	defer s.mu.Unlock()

	s.tunnels.addClient(ident, name, vhost)
	s.idents[vhost] = ident

	var err error
	for _, tun := range toList(services, vhost) {
		if tun.Name != "kite" && tun.Name != "kites" {
			s.opts.Log.Warning("unsupported %q service added during initial registration", tun.Name)
		}

		e := s.tunnels.addClientService(ident, tun)
		if e != nil {
			err = multierror.Append(err, e)
		}
	}

	if err != nil {
		s.opts.Log.Error("error registering services for %q: %s", ident, err)
	}

	s.Server.AddHost(vhost, ident)
}

func (s *Server) delClient(ident, vhost string) {
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
	delete(s.idents, vhost)
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

		l, err := s.listen("tcp", s.addr(tun.Port))
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

	l, err := s.listen("tcp", s.addr(tun.Port))
	if err != nil && tun.Port != 0 {
		s.opts.Log.Debug("failed to bind to requested port %d, binding to random one: %s", tun.Port, err)

		l, err = s.listen("tcp", s.addr(0))
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
	return net.JoinHostPort(s.privateIP, strconv.Itoa(port))
}

// RegisterServices creates a port-routed TCP tunnel for each requested service.
func (s *Server) RegisterServices(r *kite.Request) (interface{}, error) {
	resp, err := s.registerServices(r)
	if err != nil {
		s.opts.Log.Error("error serving RegisterServices for %q: %s", r.Username, err)

		return nil, err
	}

	return resp, nil
}

func (s *Server) registerServices(r *kite.Request) (interface{}, error) {
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
	vhost := host(s.tunnels.tunnel(req.Ident, "").VirtualHost)
	services := toList(req.Services, vhost)
	res := &RegisterServicesResult{
		VirtualHost: vhost,
		Services:    make(map[string]*Tunnel, len(services)),
	}

	s.opts.Log.Debug("received RegisterServices request for %q: %+v", r.Username, services)

	for _, service := range services {
		// During initial registration klient sends details about port
		// (and eventual forwarded ports) for kite and kites services,
		// which stand respectively for klient kite HTTP and HTTPS server.
		//
		// We deny user to overwrite those.
		if service.Name == "kite" || service.Name == "kites" {
			e := errors.New(service.Name + " is a reserved name for internal services")
			service.Error = e.Error()
			err = multierror.Append(err, e)
			continue
		}
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

	s.opts.Log.Debug("registered services for %q: %+v", r.Username, res)

	return res, nil
}

func (s *Server) vhost(req *RegisterRequest) string {
	return fmt.Sprintf("%s.%s.%s", req.TunnelName, req.Username, s.opts.BaseVirtualHost)
}

// Register creates a virtual host and DNS record for the user.
func (s *Server) Register(r *kite.Request) (interface{}, error) {
	resp, err := s.register(r)
	if err != nil {
		s.opts.Log.Error("error serving Register for %q: %s", r.Username, err)

		return nil, err
	}

	return resp, nil
}

func (s *Server) register(r *kite.Request) (interface{}, error) {
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

	s.opts.Log.Debug("received register request: %s", TunnelsByName(toList(req.Services, vhost)))

	// By default all addresses are routed by default with wildcard
	// CNAME. If it is disabled explicitly, we're inserting A records
	// for each tunnel instead.
	if s.opts.NoCNAME {
		if err := s.upsert(vhost); err != nil {
			return nil, err
		}
	}

	res := &RegisterResult{
		VirtualHost: vhost,
		ServerAddr:  s.opts.ServerAddr,
		Ident:       utils.RandString(32),
	}

	s.addClient(res.Ident, req.TunnelName, res.VirtualHost, req.Services)

	s.Server.OnDisconnect(res.Ident, func() error {
		s.delClient(res.Ident, res.VirtualHost)
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

func (s *Server) listen(network, addr string) (net.Listener, error) {
	host, port, err := splitHostPort(addr)
	if err != nil || port != 0 {
		return net.Listen(network, addr)
	}

	if s.opts.TCPRangeTo == 0 && s.opts.TCPRangeFrom == 0 {
		return net.Listen(network, addr)
	}

	from := s.opts.TCPRangeFrom
	if from == 0 {
		from = 10000
	}
	to := s.opts.TCPRangeTo
	if to == 0 {
		to = 65535
	}

	s.lastMu.Lock()
	port = s.last
	s.lastMu.Unlock()

	for j := 0; j < (to - from); j++ {
		if port < from || port > to {
			port = from
		}

		addr := net.JoinHostPort(host, strconv.Itoa(port))

		l, err := net.Listen(network, addr)
		if err == nil {
			s.lastMu.Lock()
			s.last = port
			s.lastMu.Unlock()

			return l, nil
		} else {
			s.opts.Log.Debug("unable to listen on %q: %s", addr, err)
		}

		port++
	}

	return nil, errors.New("unable to find available port")
}

func isLocal(tun *Tunnel, r *http.Request) bool {
	if tun.LocalAddr == "" {
		return false
	}
	_, ok := extractIPs(r)[tun.PublicIP]
	return ok
}

// TODO(rjeczalik): make it possible for services to register custom
// protocol type.
func (s *Server) discover(service string, r *http.Request) ([]*Endpoint, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	ident, ok := s.idents[r.Host]
	if !ok {
		host, port, err := net.SplitHostPort(r.Host)
		if err == nil && (port == "80" || port == "443") {
			ident, ok = s.idents[host]
		}

		if !ok {
			return nil, errors.New("virtual host not registered: " + r.Host)
		}
	}

	if service == "kite" || service == "kites" {
		return s.discoverKite(ident, r)
	}

	tun := s.tunnels.tunnel(ident, service)
	if tun == nil {
		return nil, errors.New("service not found: " + service)
	}

	s.opts.Log.Debug("%s: discovered tunnel for %s: %+v", ident, r.Host, tun)

	if isLocal(tun, r) {
		s.opts.Log.Debug("%s: found local route for %s: %s", ident, tun.PublicIP, tun.LocalAddr)

		return []*Endpoint{
			tun.localEndpoint("tcp"),
			tun.remoteEndpoint("tcp"),
		}, nil

	}

	return []*Endpoint{tun.remoteEndpoint("tcp")}, nil
}

func (s *Server) discoverKite(ident string, r *http.Request) ([]*Endpoint, error) {
	tun := s.tunnels.tunnel(ident, "kite")
	if tun == nil {
		return nil, errors.New("service not found: kite")
	}

	s.opts.Log.Debug("%s: discovered tunnel for %s: %+v", ident, r.Host, tun)

	var endpoints []*Endpoint

	if tuns := s.tunnels.tunnel(ident, "kites"); tuns != nil && isLocal(tuns, r) {
		s.opts.Log.Debug("%s: found local route for %s: %s", ident, tuns.PublicIP, tuns.LocalAddr)

		endpoints = append(endpoints, tuns.localEndpoint("https"))
	}

	if isLocal(tun, r) {
		s.opts.Log.Debug("%s: found local route for %s: %s", ident, tun.PublicIP, tun.LocalAddr)

		endpoints = append(endpoints, tun.localEndpoint("http"))
	}

	endpoints = append(endpoints, tun.remoteEndpoint("http"))

	return endpoints, nil
}

func (s *Server) discoverHandler() http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if util.HandleCORS(w, r) {
			return
		}

		endpoints, err := s.discover(strings.ToLower(mux.Vars(r)["service"]), r)
		if err != nil {
			s.opts.Log.Error("%s: discover failed for %s (%s): %s", r.RemoteAddr, r.Host, r.URL, err)

			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}

		p, err := json.Marshal(endpoints)
		if err != nil {
			s.opts.Log.Error("%s: discover failed for %s (%s): %s", r.RemoteAddr, r.Host, r.URL, err)

			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		w.Header().Set("Content-Length", strconv.Itoa(len(p)))
		w.Header().Set("Content-Type", "application/json")
		w.Write(p)
	}
}

func (s *Server) serverHandler() http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		// skip requests from localhost
		if r.Host == "localhost" {
			w.WriteHeader(200)
			return
		}

		r.URL.Path = strings.TrimPrefix(r.URL.Path, "/klient")

		s.Server.ServeHTTP(w, r)
	}
}

// NewServerKite creates a server kite for the given server.
func NewServerKite(s *Server, name, version string) (*kite.Kite, error) {
	cfg, err := konfig.ReadKiteConfig(s.opts.Debug)
	if err != nil {
		return nil, err
	}

	k := kite.NewWithConfig(name, version, cfg)

	k.Config.KontrolURL = s.opts.kontrolURL()
	k.Config.Serve = serveNoHTTP2

	if s.opts.Port != 0 {
		k.Config.Port = s.opts.Port
	}
	if s.opts.Region != "" {
		k.Config.Region = s.opts.Region
	}
	if s.opts.Environment != "" {
		k.Config.Environment = s.opts.Environment
	}
	if s.opts.Test {
		k.Config.DisableAuthentication = true
	}
	if s.opts.Debug {
		k.SetLogLevel(kite.DEBUG)
	}

	k.Log = s.opts.Log

	k.HandleFunc("register", metrics.WrapKiteHandler(s.opts.Metrics, "register", s.Register))
	k.HandleFunc("registerServices", metrics.WrapKiteHandler(s.opts.Metrics, "registerServices", s.RegisterServices))
	k.HandleHTTPFunc("/healthCheck", artifact.HealthCheckHandler(name))
	k.HandleHTTPFunc("/version", artifact.VersionHandler())

	// Tunnel helper methods, like ports, stats etc.
	k.HandleHTTPFunc("/-/discover/{service}", metrics.WrapHTTPHandler(s.opts.Metrics, "discover_service_handler", s.discoverHandler()))

	// Route all the rest requests (match all paths that does not begin with /-/).
	k.HandleHTTP(`/{rest:.?$|[^\/].+|\/[^-].+|\/-[^\/].*}`, metrics.WrapHTTPHandler(s.opts.Metrics, "rest_handler", s.serverHandler()))

	u, err := url.Parse(s.opts.registerURL())
	if err != nil {
		return nil, fmt.Errorf("error parsing registerURL: %s", err)
	}

	if err := k.RegisterForever(u); err != nil {
		return nil, fmt.Errorf("error registering to Kontrol: %s", err)
	}

	return k, nil
}

func serveNoHTTP2(l net.Listener, h http.Handler) error {
	srv := &http.Server{
		Handler:        h,
		MaxHeaderBytes: 1 << 20,
		TLSNextProto:   make(map[string]func(*http.Server, *tls.Conn, http.Handler)),
	}
	return srv.Serve(l)
}
