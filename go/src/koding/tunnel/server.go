package tunnel

import (
	"errors"
	"fmt"
	"io"
	"koding/tunnel/pool"
	"log"
	"net"
	"net/http"
	"strings"
	"sync"
	"time"
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

	// controls contains the control connection from the client to the server
	controls *controls

	// virtualHosts is used to map public hosts to remote clients
	virtualHosts *virtualHosts
}

// NewServer returns a new Server instance. It registers by default two new
// http handlers to the default.Mux which is used for establishing control
// connections and creating tunnels between public and local clients.
func NewServer() *Server {
	s := &Server{
		pending:      make(map[string]chan *tunnel),
		pools:        make(map[string]*pool.Pool),
		controls:     newControls(),
		virtualHosts: newVirtualHosts(),
	}

	http.HandleFunc(ControlPath, s.controlHandler)
	http.HandleFunc(TunnelPath, s.tunnelHandler)
	return s
}

// tunnelHandler is used to capture incoming tunnel connect requests into raw
// tunnel tcp connections.
func (s *Server) tunnelHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != "CONNECT" {
		w.Header().Set("Content-Type", "text/plain; charset=utf-8")
		w.WriteHeader(http.StatusMethodNotAllowed)
		io.WriteString(w, "405 must CONNECT\n")
		return
	}

	conn, _, err := w.(http.Hijacker).Hijack()
	if err != nil {
		log.Println("register hijacking ", r.RemoteAddr, ": ", err.Error())
		return
	}

	io.WriteString(conn, "HTTP/1.1 "+Connected+"\n\n")
	conn.SetDeadline(time.Time{})

	protocol := r.Header.Get("protocol")
	tunnelID := r.Header.Get("tunnelID")
	username := r.Header.Get("username")
	log.Printf("tunnel with protocol %s, tunnelID %s and username %s\n",
		protocol, tunnelID, username)

	s.pendingMu.Lock()
	tunnelRequester, ok := s.pending[tunnelID]
	if !ok {
		s.pendingMu.Unlock()
		log.Println("tunnel not available for id", tunnelID)
		return
	}

	delete(s.pending, tunnelID)
	s.pendingMu.Unlock()

	// we now have an encapsulated connection. send it back to the requester
	// the request can either store the conn for reusage (like http) or can
	// use it only for one session (like websocket)
	tunnelRequester <- newTunnel(conn)

}

// controlHandler is used to capture incoming control connect requests into
// raw control tcp connection. After capturing the the connection, the control
// connection starts to read and write to the control connection until the
// connection is closed. Currently only one control connection per user is allowed.
func (s *Server) controlHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != "CONNECT" {
		w.Header().Set("Content-Type", "text/plain; charset=utf-8")
		w.WriteHeader(http.StatusMethodNotAllowed)
		io.WriteString(w, "405 must CONNECT\n")
		return
	}

	username := r.Header.Get("username")
	if username == "" {
		log.Printf("empty username is connected")
		http.Error(w, "username is not set", 405)
		return
	}

	host, ok := s.GetHost(username)
	if !ok {
		log.Printf("no host is associated for username %s. please use server.AddHost()", username)
		http.Error(w, "there is no host defined for this username", 405)
		return
	}

	_, ok = s.getControl(username)
	if ok {
		log.Printf("control conn for %s already exist\n", username)
		http.Error(w, "only one control connection is allowed", 405)
		return
	}

	conn, _, err := w.(http.Hijacker).Hijack()
	if err != nil {
		log.Println("register hijacking ", r.RemoteAddr, ": ", err.Error())
		return
	}

	// ok, everthing is ready
	io.WriteString(conn, "HTTP/1.1 "+Connected+"\n\n")
	conn.SetDeadline(time.Time{})

	// create a new control struct and add it
	control := newControl(conn, username)
	s.addControl(username, control)

	// delete and close all tunnels and control connection when there is a
	// disconnection
	defer func() {
		log.Println("closing control connection for", username)
		control.Close()
		s.deleteControl(username)

		s.closePool(host)
		s.deletePool(host)
	}()

	log.Println("control connection has been established for", username)
	control.run() // blocking function
}

// ServeHTTP is a tunnel that creates an http/websocket tunnel between a
// public connection and the client connection.
func (s *Server) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if isWebsocket(r) {
		s.websocketHandleFunc(w, r)
		return
	}

	host := strings.ToLower(r.Host)
	log.Printf("http from %s to %s  -- path: %s\n", r.RemoteAddr, r.Host, r.URL.String())

	tunn, err := s.tunnelFromPool(host)
	if err != nil {
		log.Println(err)
		http.Error(w, err.Error(), 404)
		return
	}

	err = tunn.proxy(w, r)
	if err != nil {
		log.Println(err)
		http.Error(w, err.Error(), 404)
		return
	}

	// only put it back when the tunnel connection is still alive
	s.putConn(host, tunn)
}

func (s *Server) tunnelFromPool(host string) (*tunnel, error) {
	p, ok := s.getPool(host)
	if !ok {
		var err error
		// create a new pool for this host with inital 5 tunnel requests and a
		// maximum of 30 connections (this parameters should be tweaked in the
		// future). This is just for performance and allows us to connect to
		// the client immediately instead of requesting tunnel for the first
		// request.

		factory := func() (net.Conn, error) {
			return s.requestTunnel("http", host)
		}

		p, err = pool.New(5, 30, factory)
		if err != nil {
			return nil, err
		}

		s.addPool(host, p)
	}

	conn, err := p.Get()
	tunn, ok := conn.(*tunnel)
	if !ok {
		return nil, fmt.Errorf("failed to type assert of conn to tunnel", err)
	}

	return tunn, err
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
	// don't use a connection from the pool, becasue websocket connections are
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
	// get the user associated with this user
	username, ok := s.GetUsername(host)
	if !ok {
		return nil, fmt.Errorf("no virtual host available for %s", host)
	}

	// then grab the control connection that is associated with this username
	control, ok := s.getControl(username)
	if !ok {
		return nil, fmt.Errorf("no control available for %s", host)
	}

	// create an unique id to used with that tunnel
	tunnelID := randomID(32)

	// request a new http tunnel
	msg := ServerMsg{
		Protocol: protocol,
		TunnelID: tunnelID,
		Username: username,
		Host:     host,
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
		return nil, errors.New("timeout")
	}
}

func (s *Server) deletePool(host string) {
	s.poolsMu.Lock()
	defer s.poolsMu.Unlock()

	delete(s.pools, host)
}

func (s *Server) closePool(host string) {
	s.poolsMu.RLock()
	defer s.poolsMu.RUnlock()

	s.pools[host].Close()
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

func (s *Server) putConn(host string, c net.Conn) {
	s.poolsMu.RLock()
	defer s.poolsMu.RUnlock()

	s.pools[host].Put(c)
}

func (s *Server) addControl(username string, conn *control) {
	s.controls.addControl(username, conn)
}

func (s *Server) getControl(username string) (*control, bool) {
	return s.controls.getControl(username)
}

func (s *Server) deleteControl(username string) {
	s.controls.deleteControl(username)
}

// virtual hosts methods are exposed

func (s *Server) AddHost(host, username string) {
	s.virtualHosts.addHost(host, username)
}

func (s *Server) DeleteHost(host, username string) {
	s.virtualHosts.deleteHost(host)
}

func (s *Server) GetUsername(host string) (string, bool) {
	username, ok := s.virtualHosts.getUsername(host)
	return username, ok
}

func (s *Server) GetHost(username string) (string, bool) {
	host, ok := s.virtualHosts.getHost(username)
	return host, ok
}
