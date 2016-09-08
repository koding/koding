package tunneltest

import (
	"errors"
	"fmt"
	"log"
	"net"
	"net/http"
	"net/url"
	"os"
	"sort"
	"strconv"
	"sync"
	"testing"
	"time"

	"github.com/koding/tunnel"
)

var debugNet = os.Getenv("DEBUGNET") == "1"

type dbgListener struct {
	net.Listener
}

func (l dbgListener) Accept() (net.Conn, error) {
	conn, err := l.Listener.Accept()
	if err != nil {
		return nil, err
	}

	return dbgConn{conn}, nil
}

type dbgConn struct {
	net.Conn
}

func (c dbgConn) Read(p []byte) (int, error) {
	n, err := c.Conn.Read(p)
	os.Stderr.Write(p)
	return n, err
}

func (c dbgConn) Write(p []byte) (int, error) {
	n, err := c.Conn.Write(p)
	os.Stderr.Write(p)
	return n, err
}

func logf(format string, args ...interface{}) {
	if testing.Verbose() {
		log.Printf("[tunneltest] "+format, args...)
	}
}

func nonil(err ...error) error {
	for _, e := range err {
		if e != nil {
			return e
		}
	}
	return nil
}

func parseHostPort(addr string) (string, int, error) {
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

// UsableAddrs returns all tcp addresses that we can bind a listener to.
func UsableAddrs() ([]*net.TCPAddr, error) {
	addrs, err := net.InterfaceAddrs()
	if err != nil {
		return nil, err
	}

	var usable []*net.TCPAddr
	for _, addr := range addrs {
		if ipNet, ok := addr.(*net.IPNet); ok {
			if !ipNet.IP.IsLinkLocalUnicast() {
				usable = append(usable, &net.TCPAddr{IP: ipNet.IP})
			}
		}
	}

	if len(usable) == 0 {
		return nil, errors.New("no usable addresses found")
	}

	return usable, nil
}

const (
	TypeHTTP = iota
	TypeTCP
)

// Tunnel represents a single HTTP or TCP tunnel that can be served
// by TunnelTest.
type Tunnel struct {
	// Type specifies a tunnel type - either TypeHTTP (default)  or TypeTCP.
	Type int

	// Handler is a handler to use for serving tunneled connections on
	// local server. The value of this field is required to be of type:
	//
	//   - http.Handler or http.HandlerFunc for HTTP tunnels
	//   - func(net.Conn) for TCP tunnels
	//
	// Required field.
	Handler interface{}

	// LocalAddr is a network address of local server that handles
	// connections/requests with Handler.
	//
	// Optional field, takes value of "127.0.0.1:0" when empty.
	LocalAddr string

	// ClientIdent is an identifier of a client that have already
	// registered a HTTP tunnel and have established control connection.
	//
	// If the Type is TypeTCP, instead of creating new client
	// for this TCP tunnel, we add it to an existing client
	// specified by the field.
	//
	// Optional field for TCP tunnels.
	// Ignored field for HTTP tunnels.
	ClientIdent string

	// RemoteAddr is a network address of remote server, which accepts
	// connections on a tunnel server side.
	//
	// Required field for TCP tunnels.
	// Ignored field for HTTP tunnels.
	RemoteAddr string

	// RemoteAddrIdent  an identifier of an already existing listener,
	// that listens on multiple interfaces; if the RemoteAddrIdent is valid
	// identifier the IP field is required to be non-nil and RemoteAddr
	// is ignored.
	//
	// Optional field for TCP tunnels.
	// Ignored field for HTTP tunnels.
	RemoteAddrIdent string

	// IP specifies an IP address value for IP-based routing for TCP tunnels.
	// For more details see inline documentation for (*tunnel.Server).AddAddr.
	//
	// Optional field for TCP tunnels.
	// Ignored field for HTTP tunnels.
	IP net.IP

	// StateChanges listens on state transitions.
	//
	// If ClientIdent field is empty, the StateChanges will receive
	// state transition events for the newly created client.
	// Otherwise setting this field is a nop.
	StateChanges chan<- *tunnel.ClientStateChange
}

type TunnelTest struct {
	Server              *tunnel.Server
	ServerStateRecorder *StateRecorder
	Clients             map[string]*tunnel.Client
	Listeners           map[string][2]net.Listener // [0] is local listener, [1] is remote one (for TCP tunnels)
	Addrs               []*net.TCPAddr
	Tunnels             map[string]*Tunnel
	DebugNet            bool // for debugging network communication

	mu sync.Mutex // protects Listeners
}

func NewTunnelTest() (*TunnelTest, error) {
	rec := NewStateRecorder()

	cfg := &tunnel.ServerConfig{
		StateChanges: rec.C(),
		Debug:        testing.Verbose(),
	}
	s, err := tunnel.NewServer(cfg)
	if err != nil {
		return nil, err
	}

	l, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		return nil, err
	}

	if debugNet {
		l = dbgListener{l}
	}

	addrs, err := UsableAddrs()
	if err != nil {
		return nil, err
	}

	go (&http.Server{Handler: s}).Serve(l)

	return &TunnelTest{
		Server:              s,
		ServerStateRecorder: rec,
		Clients:             make(map[string]*tunnel.Client),
		Listeners:           map[string][2]net.Listener{"": {l, nil}},
		Addrs:               addrs,
		Tunnels:             make(map[string]*Tunnel),
		DebugNet:            debugNet,
	}, nil
}

// Serve creates new TunnelTest that serves the given tunnels.
//
// If tunnels is nil, DefaultTunnels() are used instead.
func Serve(tunnels map[string]*Tunnel) (*TunnelTest, error) {
	tt, err := NewTunnelTest()
	if err != nil {
		return nil, err
	}

	if err = tt.Serve(tunnels); err != nil {
		return nil, err
	}

	return tt, nil
}

func (tt *TunnelTest) serveSingle(ident string, t *Tunnel) (bool, error) {
	// Verify tunnel dependencies for TCP tunnels.
	if t.Type == TypeTCP {
		// If tunnel specified by t.Client was not already started,
		// skip and move on.
		if _, ok := tt.Clients[t.ClientIdent]; t.ClientIdent != "" && !ok {
			return false, nil
		}

		// Verify the TCP tunnel whose remote endpoint listens on multiple
		// interfaces is already served.
		if t.RemoteAddrIdent != "" {
			if _, ok := tt.Listeners[t.RemoteAddrIdent]; !ok {
				return false, nil
			}

			if tt.Tunnels[t.RemoteAddrIdent].Type != TypeTCP {
				return false, fmt.Errorf("expected tunnel %q to be of TCP type", t.RemoteAddrIdent)
			}
		}
	}

	l, err := net.Listen("tcp", t.LocalAddr)
	if err != nil {
		return false, fmt.Errorf("failed to listen on %q for %q tunnel: %s", t.LocalAddr, ident, err)
	}

	if tt.DebugNet {
		l = dbgListener{l}
	}

	localAddr := l.Addr().String()
	httpProxy := &tunnel.HTTPProxy{LocalAddr: localAddr}
	tcpProxy := &tunnel.TCPProxy{FetchLocalAddr: tt.fetchLocalAddr}

	cfg := &tunnel.ClientConfig{
		Identifier: ident,
		ServerAddr: tt.ServerAddr().String(),
		Proxy: tunnel.Proxy(tunnel.ProxyFuncs{
			HTTP: httpProxy.Proxy,
			TCP:  tcpProxy.Proxy,
		}),
		StateChanges: t.StateChanges,
		Debug:        testing.Verbose(),
	}

	// Register tunnel:
	//
	//   - start tunnel.Client (tt.Clients[ident]) or reuse existing one (tt.Clients[t.ExistingClient])
	//   - listen on local address and start local server (tt.Listeners[ident][0])
	//   - register tunnel on tunnel.Server
	//
	switch t.Type {
	case TypeHTTP:
		// TODO(rjeczalik): refactor to separate method

		h, ok := t.Handler.(http.Handler)
		if !ok {
			h, ok = t.Handler.(http.HandlerFunc)
			if !ok {
				fn, ok := t.Handler.(func(http.ResponseWriter, *http.Request))
				if !ok {
					return false, fmt.Errorf("invalid handler type for %q tunnel: %T", ident, t.Handler)
				}

				h = http.HandlerFunc(fn)
			}

		}

		logf("serving on local %s for HTTP tunnel %q", l.Addr(), ident)

		go (&http.Server{Handler: h}).Serve(l)

		tt.Server.AddHost(localAddr, ident)

		tt.mu.Lock()
		tt.Listeners[ident] = [2]net.Listener{l, nil}
		tt.mu.Unlock()

		if err := tt.addClient(ident, cfg); err != nil {
			return false, fmt.Errorf("error creating client for %q tunnel: %s", ident, err)
		}

		logf("registered HTTP tunnel: host=%s, ident=%s", localAddr, ident)

	case TypeTCP:
		// TODO(rjeczalik): refactor to separate method

		h, ok := t.Handler.(func(net.Conn))
		if !ok {
			return false, fmt.Errorf("invalid handler type for %q tunnel: %T", ident, t.Handler)
		}

		logf("serving on local %s for TCP tunnel %q", l.Addr(), ident)

		go func() {
			for {
				conn, err := l.Accept()
				if err != nil {
					log.Printf("failed accepting conn for %q tunnel: %s", ident, err)
					return
				}

				go h(conn)
			}
		}()

		var remote net.Listener

		if t.RemoteAddrIdent != "" {
			tt.mu.Lock()
			remote = tt.Listeners[t.RemoteAddrIdent][1]
			tt.mu.Unlock()
		} else {
			remote, err = net.Listen("tcp", t.RemoteAddr)
			if err != nil {
				return false, fmt.Errorf("failed to listen on %q for %q tunnel: %s", t.RemoteAddr, ident, err)
			}
		}

		// addrIdent holds identifier of client which is going to have registered
		// tunnel via (*tunnel.Server).AddAddr
		addrIdent := ident
		if t.ClientIdent != "" {
			tt.Clients[ident] = tt.Clients[t.ClientIdent]
			addrIdent = t.ClientIdent
		}

		tt.Server.AddAddr(remote, t.IP, addrIdent)

		tt.mu.Lock()
		tt.Listeners[ident] = [2]net.Listener{l, remote}
		tt.mu.Unlock()

		if _, ok := tt.Clients[ident]; !ok {
			if err := tt.addClient(ident, cfg); err != nil {
				return false, fmt.Errorf("error creating client for %q tunnel: %s", ident, err)
			}
		}

		logf("registered TCP tunnel: listener=%s, ip=%v, ident=%s", remote.Addr(), t.IP, addrIdent)

	default:
		return false, fmt.Errorf("unknown %q tunnel type: %d", ident, t.Type)
	}

	return true, nil
}

func (tt *TunnelTest) addClient(ident string, cfg *tunnel.ClientConfig) error {
	if _, ok := tt.Clients[ident]; ok {
		return fmt.Errorf("tunnel %q is already being served", ident)
	}

	c, err := tunnel.NewClient(cfg)
	if err != nil {
		return err
	}

	done := make(chan struct{})

	tt.Server.OnConnect(ident, func() error {
		close(done)
		return nil
	})

	go c.Start()
	<-c.StartNotify()

	select {
	case <-time.After(10 * time.Second):
		return errors.New("timed out after 10s waiting on client to establish control conn")
	case <-done:
	}

	tt.Clients[ident] = c
	return nil
}

func (tt *TunnelTest) Serve(tunnels map[string]*Tunnel) error {
	if len(tunnels) == 0 {
		return errors.New("no tunnels to serve")
	}

	// Since one tunnels depends on others do 3 passes to start them
	// all, each started tunnel is removed from the tunnels map.
	// After 3 passes all of them must be started, otherwise the
	// configuration is bad:
	//
	//   - first pass starts HTTP tunnels as new client tunnels
	//   - second pass starts TCP tunnels that rely on on already existing client tunnels (t.ClientIdent)
	//   - third pass starts TCP tunnels that rely on on already existing TCP tunnels (t.RemoteAddrIdent)
	//
	for i := 0; i < 3; i++ {
		if err := tt.popServedDeps(tunnels); err != nil {
			return err
		}
	}

	if len(tunnels) != 0 {
		unresolved := make([]string, len(tunnels))
		for ident := range tunnels {
			unresolved = append(unresolved, ident)
		}
		sort.Strings(unresolved)

		return fmt.Errorf("unable to start tunnels due to unresolved dependencies: %v", unresolved)
	}

	return nil
}

func (tt *TunnelTest) popServedDeps(tunnels map[string]*Tunnel) error {
	for ident, t := range tunnels {
		ok, err := tt.serveSingle(ident, t)
		if err != nil {
			return err
		}

		if ok {
			// Remove already started tunnels so they won't get started again.
			delete(tunnels, ident)
			tt.Tunnels[ident] = t
		}
	}

	return nil
}

func (tt *TunnelTest) fetchLocalAddr(port int) (string, error) {
	tt.mu.Lock()
	defer tt.mu.Unlock()

	for _, l := range tt.Listeners {
		if l[1] == nil {
			// this listener does not belong to a TCP tunnel
			continue
		}

		_, remotePort, err := parseHostPort(l[1].Addr().String())
		if err != nil {
			return "", err
		}

		if port == remotePort {
			return l[0].Addr().String(), nil
		}
	}

	return "", fmt.Errorf("no route for %d port", port)
}

func (tt *TunnelTest) ServerAddr() net.Addr {
	return tt.Listeners[""][0].Addr()
}

// Addr gives server endpoint of the TCP tunnel for the given ident.
//
// If the tunnel does not exist or is a HTTP one, TunnelAddr return nil.
func (tt *TunnelTest) Addr(ident string) net.Addr {
	l, ok := tt.Listeners[ident]
	if !ok {
		return nil
	}

	return l[1].Addr()
}

// Request creates a HTTP request to a server endpoint of the HTTP tunnel
// for the given ident.
//
// If the tunnel does not exist, Request returns nil.
func (tt *TunnelTest) Request(ident string, query url.Values) *http.Request {
	l, ok := tt.Listeners[ident]
	if !ok {
		return nil
	}

	var raw string
	if query != nil {
		raw = query.Encode()
	}

	return &http.Request{
		Method: "GET",
		URL: &url.URL{
			Scheme:   "http",
			Host:     tt.ServerAddr().String(),
			Path:     "/",
			RawQuery: raw,
		},
		Proto:      "HTTP/1.1",
		ProtoMajor: 1,
		ProtoMinor: 1,
		Host:       l[0].Addr().String(),
	}
}

func (tt *TunnelTest) Close() (err error) {
	// Close tunnel.Clients.
	clients := make(map[*tunnel.Client]struct{})
	for _, c := range tt.Clients {
		clients[c] = struct{}{}
	}
	for c := range clients {
		err = nonil(err, c.Close())
	}

	// Stop all TCP/HTTP servers.
	listeners := make(map[net.Listener]struct{})
	for _, l := range tt.Listeners {
		for _, l := range l {
			if l != nil {
				listeners[l] = struct{}{}
			}
		}
	}
	for l := range listeners {
		err = nonil(err, l.Close())
	}

	return err
}
