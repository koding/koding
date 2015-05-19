package tunnel

import (
	"errors"
	"fmt"
	"io"
	"log"
	"net"
	"net/http"
	"path"
	"strings"
	"sync"
	"time"

	"github.com/fatih/pool"
	"github.com/hashicorp/yamux"
)

// Server satisfies the http.Handler interface. It is responsible of tracking
// tunnels and creating tunnels between remote and local connection.
type Server struct {
	// pending contains the channel that is associated with each new tunnel request
	pending   map[string]chan *tunnel
	pendingMu sync.Mutex // protects the pending map

	// pools is containing a connection pool for each virtual host.
	pools   map[string]*pool.Pool
	poolsMu sync.RWMutex // protects the pools map

	// sessions contains a session per virtual host. Sessions provides
	// multiplexing over one connection
	sessions   map[string]*yamux.Session
	sessionsMu sync.RWMutex // protects the sessions map

	// controls contains the control connection from the client to the server
	controls *controls

	// virtualHosts is used to map public hosts to remote clients
	virtualHosts *virtualHosts
}

// NewServer returns a new Server instance. It registers by default two new
// HTTP handlers to the default.Mux which is used for establishing control
// connections and creating tunnels between public and local clients.
func NewServer() *Server {
	s := &Server{
		pending:      make(map[string]chan *tunnel),
		pools:        make(map[string]*pool.Pool),
		sessions:     make(map[string]*yamux.Session),
		controls:     newControls(),
		virtualHosts: newVirtualHosts(),
	}

	http.Handle(ControlPath, checkConnect(s.ControlHandler))
	http.Handle(TunnelPath, checkConnect(s.TunnelHandler))
	return s
}

// checkConnect checks wether the incoming request is HTTP CONNECT method. If
func checkConnect(fn func(w http.ResponseWriter, r *http.Request) error) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != "CONNECT" {
			w.Header().Set("Content-Type", "text/plain; charset=utf-8")
			w.WriteHeader(http.StatusMethodNotAllowed)
			io.WriteString(w, "405 must CONNECT\n")
			return
		}

		err := fn(w, r)
		if err != nil {
			http.Error(w, err.Error(), 502)
		}
	})
}

// TunnelHandler is used to capture incoming tunnel connect requests into raw
// tunnel TCP connections.
func (s *Server) TunnelHandler(w http.ResponseWriter, r *http.Request) error {
	protocol := r.Header.Get("protocol")
	tunnelID := r.Header.Get("tunnelID")
	identifier := r.Header.Get("identifier")
	log.Printf("tunnel with protocol %s, tunnelID %s and identifier %s\n",
		protocol, tunnelID, identifier)

	s.pendingMu.Lock()
	tunnelRequester, ok := s.pending[tunnelID]
	if !ok {
		s.pendingMu.Unlock()
		return fmt.Errorf("tunnel not available for id %s", tunnelID)
	}

	delete(s.pending, tunnelID)
	s.pendingMu.Unlock()

	conn, _, err := w.(http.Hijacker).Hijack()
	if err != nil {
		return fmt.Errorf("hijack not possible %s", err)
	}

	io.WriteString(conn, "HTTP/1.1 "+Connected+"\n\n")
	conn.SetDeadline(time.Time{})

	// we now have an encapsulated connection. send it back to the requester
	// the request can either store the conn for re-usage (like http) or can
	// use it only for one session (like websocket)
	tunnelRequester <- newTunnel(conn)
	return nil
}

// ControlHandler is used to capture incoming control connect requests into
// raw control TCP connection. After capturing the the connection, the control
// connection starts to read and write to the control connection until the
// connection is closed. Currently only one control connection per user is allowed.
func (s *Server) ControlHandler(w http.ResponseWriter, r *http.Request) error {
	identifier := r.Header.Get("identifier")
	if identifier == "" {
		return fmt.Errorf("empty identifier is connected")
	}

	host, ok := s.GetHost(identifier)
	if !ok {
		return fmt.Errorf("no host associated for identifier %s. please use server.AddHost()", identifier)
	}

	_, ok = s.getControl(identifier)
	if ok {
		return fmt.Errorf("control conn for %s already exist\n", identifier)
	}

	conn, _, err := w.(http.Hijacker).Hijack()
	if err != nil {
		return fmt.Errorf("hijack not possible %s", err)
	}

	io.WriteString(conn, "HTTP/1.1 "+Connected+"\n\n")
	conn.SetDeadline(time.Time{})

	// create a new control struct and add it
	ready := make(chan bool)
	control := newControl(conn, identifier, ready)
	s.addControl(identifier, control)

	// delete and close all tunnels and control connection when there is a
	// disconnection.
	defer func() {
		control.Close()
		s.deleteControl(identifier)
		s.deletePool(host)
		log.Println("control connection has been closed for", identifier)
	}()

	// create initial five tunnel connections to speed up initial http requests
	go func() {
		<-ready // wait until control is ready
		s.createPool(host)
	}()

	log.Println("control connection has been established for", identifier)
	control.run() // blocking function
	return nil
}

// ServeHTTP is a tunnel that creates an http/websocket tunnel between a
// public connection and the client connection.
func (s *Server) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	// if the user didn't add the control and tunnel handler manually, we'll
	// going to infer and call the respective path handlers.
	switch path.Clean(r.URL.Path) + "/" {
	case ControlPath:
		checkConnect(s.ControlHandler).ServeHTTP(w, r)
		return
	case TunnelPath:
		checkConnect(s.TunnelHandler).ServeHTTP(w, r)
		return
	}

	if isWebsocket(r) {
		s.websocketHandleFunc(w, r)
		return
	}

	err := s.makeRequest(w, r, 0)
	if err != nil {
		log.Println(err)
		http.Error(w, "tunnel server-client disconnection.", 502)
		return
	}
}

// makeRequest makes an HTTP request from the public connection to the client
// on top of the tunnel connection. It's a recursive function, that is, if the
// request on a certain tunnel fails, it goes and applies the request to the
// next one.
func (s *Server) makeRequest(w http.ResponseWriter, r *http.Request, iteration int) error {
	host := strings.ToLower(r.Host)
	log.Printf("http from %s to %s  -- path: %s\n", r.RemoteAddr, r.Host, r.URL.String())

	tunn, err := s.tunnelFromPool(host)
	if err != nil {
		return err
	}

	if iteration > s.capacityOfPool(host) {
		return errors.New("maximum recursive iteration has been reached. aborting")
	}

	err = tunn.proxy(w, r)
	if err != nil {
		// this is mostly due to closing of tunnel connection via local
		// client. Therefore go and get the next tunnel conn from the pool. If
		// all the tunnels are closed, tunnelFromPool will create new tunnels
		// that eventually will finish this request.
		log.Println("making another request")
		iteration++
		return s.makeRequest(w, r, iteration)
	}

	// only put it back when the tunnel connection is still alive
	s.putConn(host, tunn)
	return nil
}

// tunnelFromSessions picks the tunnel from the sessions map associated with
// the with the host.
func (s *Server) tunnelFromSessions(host string) (*tunnel, error) {
	s.sessionsMu.Lock()
	defer s.sessionsMu.RLock()

	session, ok := s.sessions[host]
	if !ok {
		return nil, fmt.Errorf("no session exists for %s", host)
	}

	conn, err := session.Accept()
	if err != nil {
		return nil, err
	}

	return newTunnel(conn), nil
}

// tunnelFromPool picks up the next tunnel from the connection pool. It also
// creates a new pool when the pool for the given host doesn't exist.
func (s *Server) tunnelFromPool(host string) (*tunnel, error) {
	p, ok := s.getPool(host)
	if !ok {
		return nil, fmt.Errorf("no pool exists for %s", host)
	}

	conn, err := p.Get()
	if err != nil {
		return nil, err
	}

	tunn, ok := conn.(*tunnel)
	if !ok {
		return nil, fmt.Errorf("failed to type assert net.Conn to tunnel %s", err)
	}

	return tunn, nil
}

func (s *Server) websocketHandleFunc(w http.ResponseWriter, r *http.Request) {
	log.Println("websocket handler invoked", r.URL.String())
	host := strings.ToLower(r.Host)

	tunnelConn, err := s.websocketTunnelConn(host)
	if err != nil {
		fmt.Println("err", err)
		http.Error(w, err.Error(), 404)
		return
	}

	err = r.Write(tunnelConn)
	if err != nil {
		err := fmt.Sprintf("write to tunnel %s", err)
		http.Error(w, err, 404)
		return
	}

	publicConn, _, err := w.(http.Hijacker).Hijack()
	if err != nil {
		log.Println("websocket hijacking ", err)
		return
	}
	defer publicConn.Close()

	<-join(tunnelConn, publicConn)

	// close tunnel and public connection if the websocket connection is closed
	tunnelConn.Close()
	publicConn.Close()
}

func (s *Server) websocketTunnelConn(host string) (net.Conn, error) {
	// don't use a connection from the pool, because websocket connections are
	// persistent and not reusable.
	tunnel, err := s.requestTunnel("websocket", host)
	if err != nil {
		return nil, err
	}

	return tunnel, nil
}

// requestTunnel makes a request to the control connection to get a new
// tunnel from the client. It sends the request of a new tunnel directly to
// the client, which then opens a new tunnel to be used.
func (s *Server) requestTunnel(protocol, host string) (*tunnel, error) {
	// get the identifier associated with this host
	identifier, ok := s.GetIdentifier(host)
	if !ok {
		return nil, fmt.Errorf("no virtual host available for %s", host)
	}

	// then grab the control connection that is associated with this identifier
	control, ok := s.getControl(identifier)
	if !ok {
		return nil, fmt.Errorf("no control available for %s", host)
	}

	// create an unique id to used with that tunnel
	tunnelID := randomID(32)

	// request a new http tunnel
	msg := ServerMsg{
		Protocol:   protocol,
		TunnelID:   tunnelID,
		Identifier: identifier,
		Host:       host,
	}

	s.pendingMu.Lock()
	pendingTunnel := make(chan *tunnel)
	s.pending[tunnelID] = pendingTunnel

	// send this after creating the pendingTunnel, otherwise we could get a
	// deadlock when a the tunnelHandler is invoked before we create this
	// channel.
	control.send(msg)
	s.pendingMu.Unlock()

	// now wait until our tunnel is established. if the tunnel has the
	// right ID it will send a message to this channel, which releases the
	// blocking channel. If we don't get it in 10 seconds we will timeout
	select {
	case tunnel := <-pendingTunnel:
		return tunnel, nil
	case <-time.After(time.Second * 10):
		delete(s.pending, tunnelID)
		return nil, errors.New("timeout getting tunnel")
	}
}

func (s *Server) deletePool(host string) {
	s.poolsMu.Lock()
	defer s.poolsMu.Unlock()

	s.pools[host].Close()
	delete(s.pools, host)
}

func (s *Server) getPool(host string) (*pool.Pool, bool) {
	s.poolsMu.RLock()
	defer s.poolsMu.RUnlock()

	p, ok := s.pools[host]
	return p, ok
}

func (s *Server) addPool(host string, p *pool.Pool) {
	s.poolsMu.Lock()
	defer s.poolsMu.Unlock()

	s.pools[host] = p
}

func (s *Server) createPool(host string) {
	s.poolsMu.Lock()
	defer s.poolsMu.Unlock()

	factory := func() (net.Conn, error) {
		tunn, err := s.requestTunnel("http", host)
		return tunn, err
	}

	// create a new pool for this host with initial 5 tunnel requests and a
	// maximum of 30 connections (this parameters should be tweaked in the
	// future). This is just for performance and allows us to connect to
	// the client immediately instead of requesting tunnel for the first
	// request.
	p, err := pool.New(5, 30, factory)
	if err != nil {
		return
	}

	s.pools[host] = p
}

func (s *Server) capacityOfPool(host string) int {
	p, _ := s.getPool(host)
	return p.MaximumCapacity()
}

func (s *Server) putConn(host string, c net.Conn) {
	s.poolsMu.RLock()
	defer s.poolsMu.RUnlock()

	s.pools[host].Put(c)
}

func (s *Server) addControl(identifier string, conn *control) {
	s.controls.addControl(identifier, conn)
}

func (s *Server) getControl(identifier string) (*control, bool) {
	return s.controls.getControl(identifier)
}

func (s *Server) deleteControl(identifier string) {
	s.controls.deleteControl(identifier)
}

// virtual hosts methods are exposed

func (s *Server) AddHost(host, identifier string) {
	s.virtualHosts.addHost(host, identifier)
}

func (s *Server) DeleteHost(host, identifier string) {
	s.virtualHosts.deleteHost(host)
}

func (s *Server) GetIdentifier(host string) (string, bool) {
	identifier, ok := s.virtualHosts.getIdentifier(host)
	return identifier, ok
}

func (s *Server) GetHost(identifier string) (string, bool) {
	host, ok := s.virtualHosts.getHost(identifier)
	return host, ok
}
