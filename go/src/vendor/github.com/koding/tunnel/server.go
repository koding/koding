// Package tunnel is a server/client package that enables to proxy public
// connections to your local machine over a tunnel connection from the local
// machine to the public server.
package tunnel

import (
	"bufio"
	"errors"
	"fmt"
	"io"
	"net"
	"net/http"
	"os"
	"path"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/koding/logging"
	"github.com/koding/tunnel/proto"

	"github.com/hashicorp/yamux"
)

var (
	errNoClientSession = errors.New("no client session established")
	defaultTimeout     = 10 * time.Second
)

// Server is responsible for proxying public connections to the client over a
// tunnel connection. It also listens to control messages from the client.
type Server struct {
	// pending contains the channel that is associated with each new tunnel request.
	pending map[string]chan net.Conn
	// pendingMu protects the pending map.
	pendingMu sync.Mutex

	// sessions contains a session per virtual host.
	// Sessions provides multiplexing over one connection.
	sessions map[string]*yamux.Session
	// sessionsMu protects sessions.
	sessionsMu sync.Mutex

	// controls contains the control connection from the client to the server.
	controls *controls

	// virtualHosts is used to map public hosts to remote clients.
	virtualHosts vhostStorage

	// virtualAddrs.
	virtualAddrs *vaddrStorage

	// connCh is used to publish accepted connections for tcp tunnels.
	connCh chan net.Conn

	// onConnectCallbacks contains client callbacks called when control
	// session is established for a client with given identifier.
	onConnectCallbacks *callbacks

	// onDisconnectCallbacks contains client callbacks called when control
	// session is closed for a client with given identifier.
	onDisconnectCallbacks *callbacks

	// states represents current clients' connections state.
	states map[string]ClientState
	// statesMu protects states.
	statesMu sync.RWMutex
	// stateCh notifies receiver about client state changes.
	stateCh chan<- *ClientStateChange

	// httpDirector is provided by ServerConfig, if not nil decorates http requests
	// before forwarding them to client.
	httpDirector func(*http.Request)

	// yamuxConfig is passed to new yamux.Session's
	yamuxConfig *yamux.Config

	log logging.Logger
}

// ServerConfig defines the configuration for the Server
type ServerConfig struct {
	// StateChanges receives state transition details each time client
	// connection state changes. The channel is expected to be sufficiently
	// buffered to keep up with event pace.
	//
	// If nil, no information about state transitions are dispatched
	// by the library.
	StateChanges chan<- *ClientStateChange

	// Director is a function that modifies HTTP request into a new HTTP request
	// before sending to client. If nil no modifications are done.
	Director func(*http.Request)

	// Debug enables debug mode, enable only if you want to debug the server
	Debug bool

	// Log defines the logger. If nil a default logging.Logger is used.
	Log logging.Logger

	// YamuxConfig defines the config which passed to every new yamux.Session. If nil
	// yamux.DefaultConfig() is used.
	YamuxConfig *yamux.Config
}

// NewServer creates a new Server. The defaults are used if config is nil.
func NewServer(cfg *ServerConfig) (*Server, error) {
	yamuxConfig := yamux.DefaultConfig()
	if cfg.YamuxConfig != nil {
		if err := yamux.VerifyConfig(cfg.YamuxConfig); err != nil {
			return nil, err
		}

		yamuxConfig = cfg.YamuxConfig
	}

	log := newLogger("tunnel-server", cfg.Debug)
	if cfg.Log != nil {
		log = cfg.Log
	}

	connCh := make(chan net.Conn)

	opts := &vaddrOptions{
		connCh: connCh,
		log:    log,
	}

	s := &Server{
		pending:               make(map[string]chan net.Conn),
		sessions:              make(map[string]*yamux.Session),
		onConnectCallbacks:    newCallbacks("OnConnect"),
		onDisconnectCallbacks: newCallbacks("OnDisconnect"),
		virtualHosts:          newVirtualHosts(),
		virtualAddrs:          newVirtualAddrs(opts),
		controls:              newControls(),
		states:                make(map[string]ClientState),
		stateCh:               cfg.StateChanges,
		httpDirector:          cfg.Director,
		yamuxConfig:           yamuxConfig,
		connCh:                connCh,
		log:                   log,
	}

	go s.serveTCP()

	return s, nil
}

// ServeHTTP is a tunnel that creates an http/websocket tunnel between a
// public connection and the client connection.
func (s *Server) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	// if the user didn't add the control and tunnel handler manually, we'll
	// going to infer and call the respective path handlers.
	switch path.Clean(r.URL.Path) + "/" {
	case proto.ControlPath:
		s.checkConnect(s.controlHandler).ServeHTTP(w, r)
		return
	}

	if err := s.handleHTTP(w, r); err != nil {
		if !strings.Contains(err.Error(), "no virtual host available") { // this one is outputted too much, unnecessarily
			s.log.Error("remote %s (%s): %s", r.RemoteAddr, r.RequestURI, err)
		}
		http.Error(w, err.Error(), http.StatusBadGateway)
	}
}

// handleHTTP handles a single HTTP request
func (s *Server) handleHTTP(w http.ResponseWriter, r *http.Request) error {
	s.log.Debug("HandleHTTP request:")
	s.log.Debug("%v", r)

	if s.httpDirector != nil {
		s.httpDirector(r)
	}

	hostPort := strings.ToLower(r.Host)
	if hostPort == "" {
		return errors.New("request host is empty")
	}

	// if someone hits foo.example.com:8080, this should be proxied to
	// localhost:8080, so send the port to the client so it knows how to proxy
	// correctly. If no port is available, it's up to client how to interpret it
	host, port, err := parseHostPort(hostPort)
	if err != nil {
		// no need to return, just continue lazily, port will be 0, which in
		// our case will be proxied to client's local servers port 80
		s.log.Debug("No port available for %q, sending port 80 to client", hostPort)
	}

	// get the identifier associated with this host
	identifier, ok := s.getIdentifier(hostPort)
	if !ok {
		// fallback to host
		identifier, ok = s.getIdentifier(host)
		if !ok {
			return fmt.Errorf("no virtual host available for %q", hostPort)
		}
	}

	if isWebsocketConn(r) {
		s.log.Debug("handling websocket connection")

		return s.handleWSConn(w, r, identifier, port)
	}

	stream, err := s.dial(identifier, proto.HTTP, port)
	if err != nil {
		return err
	}
	defer func() {
		s.log.Debug("Closing stream")
		stream.Close()
	}()

	if err := r.Write(stream); err != nil {
		return err
	}

	s.log.Debug("Session opened to client, writing request to client")
	resp, err := http.ReadResponse(bufio.NewReader(stream), r)
	if err != nil {
		return fmt.Errorf("read from tunnel: %s", err.Error())
	}

	defer func() {
		if resp.Body != nil {
			if err := resp.Body.Close(); err != nil && err != io.ErrUnexpectedEOF {
				s.log.Error("resp.Body Close error: %s", err.Error())
			}
		}
	}()

	s.log.Debug("Response received, writing back to public connection: %+v", resp)

	copyHeader(w.Header(), resp.Header)
	w.WriteHeader(resp.StatusCode)

	if _, err := io.Copy(w, resp.Body); err != nil {
		if err == io.ErrUnexpectedEOF {
			s.log.Debug("Client closed the connection, couldn't copy response")
		} else {
			s.log.Error("copy err: %s", err) // do not return, because we might write multipe headers
		}
	}

	return nil
}

func (s *Server) serveTCP() {
	for conn := range s.connCh {
		go s.serveTCPConn(conn)
	}
}

func (s *Server) serveTCPConn(conn net.Conn) {
	err := s.handleTCPConn(conn)
	if err != nil {
		s.log.Warning("failed to serve %q: %s", conn.RemoteAddr(), err)
		conn.Close()
	}
}

func (s *Server) handleWSConn(w http.ResponseWriter, r *http.Request, ident string, port int) error {
	hj, ok := w.(http.Hijacker)
	if !ok {
		return fmt.Errorf("webserver doesn't support hijacking: %T", w)
	}

	conn, _, err := hj.Hijack()
	if err != nil {
		return fmt.Errorf("hijack not possible: %s", err)
	}

	stream, err := s.dial(ident, proto.WS, port)
	if err != nil {
		return err
	}

	if err := r.Write(stream); err != nil {
		err = errors.New("unable to write upgrade request: " + err.Error())
		return nonil(err, stream.Close())
	}

	resp, err := http.ReadResponse(bufio.NewReader(stream), r)
	if err != nil {
		err = errors.New("unable to read upgrade response: " + err.Error())
		return nonil(err, stream.Close())
	}

	if err := resp.Write(conn); err != nil {
		err = errors.New("unable to write upgrade response: " + err.Error())
		return nonil(err, stream.Close())
	}

	var wg sync.WaitGroup
	wg.Add(2)

	go s.proxy(&wg, conn, stream)
	go s.proxy(&wg, stream, conn)

	wg.Wait()

	return nonil(stream.Close(), conn.Close())
}

func (s *Server) handleTCPConn(conn net.Conn) error {
	ident, ok := s.virtualAddrs.getIdent(conn)
	if !ok {
		return fmt.Errorf("no virtual address available for %s", conn.LocalAddr())
	}

	_, port, err := parseHostPort(conn.LocalAddr().String())
	if err != nil {
		return err
	}

	stream, err := s.dial(ident, proto.TCP, port)
	if err != nil {
		return err
	}

	var wg sync.WaitGroup
	wg.Add(2)

	go s.proxy(&wg, conn, stream)
	go s.proxy(&wg, stream, conn)

	wg.Wait()

	return nonil(stream.Close(), conn.Close())
}

func (s *Server) proxy(wg *sync.WaitGroup, dst, src net.Conn) {
	defer wg.Done()

	s.log.Debug("tunneling %s -> %s", src.RemoteAddr(), dst.RemoteAddr())
	n, err := io.Copy(dst, src)
	s.log.Debug("tunneled %d bytes %s -> %s: %v", n, src.RemoteAddr(), dst.RemoteAddr(), err)
}

func (s *Server) dial(identifier string, p proto.Type, port int) (net.Conn, error) {
	control, ok := s.getControl(identifier)
	if !ok {
		return nil, errNoClientSession
	}

	session, err := s.getSession(identifier)
	if err != nil {
		return nil, err
	}

	msg := proto.ControlMessage{
		Action:    proto.RequestClientSession,
		Protocol:  p,
		LocalPort: port,
	}

	s.log.Debug("Sending control msg %+v", msg)

	// ask client to open a session to us, so we can accept it
	if err := control.send(msg); err != nil {
		// we might have several issues here, either the stream is closed, or
		// the session is going be shut down, the underlying connection might
		// be broken. In all cases, it's not reliable anymore having a client
		// session.
		control.Close()
		s.deleteControl(identifier)
		return nil, errNoClientSession
	}

	var stream net.Conn
	acceptStream := func() error {
		stream, err = session.Accept()
		return err
	}

	// if we don't receive anything from the client, we'll timeout
	s.log.Debug("Waiting for session accept")

	select {
	case err := <-async(acceptStream):
		return stream, err
	case <-time.After(defaultTimeout):
		return nil, errors.New("timeout getting session")
	}
}

// controlHandler is used to capture incoming tunnel connect requests into raw
// tunnel TCP connections.
func (s *Server) controlHandler(w http.ResponseWriter, r *http.Request) (ctErr error) {
	identifier := r.Header.Get(proto.ClientIdentifierHeader)
	_, ok := s.getHost(identifier)
	if !ok {
		return fmt.Errorf("no host associated for identifier %s. please use server.AddHost()", identifier)
	}

	ct, ok := s.getControl(identifier)
	if ok {
		ct.Close()
		s.deleteControl(identifier)
		s.deleteSession(identifier)
		s.log.Warning("Control connection for %q already exists. This is a race condition and needs to be fixed on client implementation", identifier)
		return fmt.Errorf("control conn for %s already exist. \n", identifier)
	}

	s.log.Debug("Tunnel with identifier %s", identifier)

	hj, ok := w.(http.Hijacker)
	if !ok {
		return fmt.Errorf("webserver doesn't support hijacking: %T", w)
	}

	conn, _, err := hj.Hijack()
	if err != nil {
		return fmt.Errorf("hijack not possible: %s", err)
	}

	if _, err := io.WriteString(conn, "HTTP/1.1 "+proto.Connected+"\n\n"); err != nil {
		return fmt.Errorf("error writing response: %s", err)
	}

	if err := conn.SetDeadline(time.Time{}); err != nil {
		return fmt.Errorf("error setting connection deadline: %s", err)
	}

	s.log.Debug("Creating control session")
	session, err := yamux.Server(conn, s.yamuxConfig)
	if err != nil {
		return err
	}
	s.addSession(identifier, session)

	var stream net.Conn

	// close and delete the session/stream if something goes wrong
	defer func() {
		if ctErr != nil {
			if stream != nil {
				stream.Close()
			}
			s.deleteSession(identifier)
		}
	}()

	acceptStream := func() error {
		stream, err = session.Accept()
		return err
	}

	// if we don't receive anything from the client, we'll timeout
	select {
	case err := <-async(acceptStream):
		if err != nil {
			return err
		}
	case <-time.After(time.Second * 10):
		return errors.New("timeout getting session")
	}

	s.log.Debug("Initiating handshake protocol")
	buf := make([]byte, len(proto.HandshakeRequest))
	if _, err := stream.Read(buf); err != nil {
		return err
	}

	if string(buf) != proto.HandshakeRequest {
		return fmt.Errorf("handshake aborted. got: %s", string(buf))
	}

	if _, err := stream.Write([]byte(proto.HandshakeResponse)); err != nil {
		return err
	}

	// setup control stream and start to listen to messages
	ct = newControl(stream)
	s.addControl(identifier, ct)
	go s.listenControl(ct)

	s.log.Debug("Control connection is setup")
	return nil
}

// listenControl listens to messages coming from the client.
func (s *Server) listenControl(ct *control) {
	s.onConnect(ct.identifier)

	for {
		var msg map[string]interface{}
		err := ct.dec.Decode(&msg)
		if err != nil {
			host, _ := s.getHost(ct.identifier)
			s.log.Debug("Closing client connection: '%s', %s'", host, ct.identifier)

			// close client connection so it reconnects again
			ct.Close()

			// don't forget to cleanup anything
			s.deleteControl(ct.identifier)
			s.deleteSession(ct.identifier)

			s.onDisconnect(ct.identifier, err)

			if err != io.EOF {
				s.log.Error("decode err: %s", err)
			}
			return
		}

		// right now we don't do anything with the messages, but because the
		// underlying connection needs to establihsed, we know when we have
		// disconnection(above), so we can cleanup the connection.
		s.log.Debug("msg: %s", msg)
	}
}

// OnConnect invokes a callback for client with given identifier,
// when it establishes a control session.
// After a client is connected, the associated function
// is also removed and needs to be added again.
func (s *Server) OnConnect(identifier string, fn func() error) {
	s.onConnectCallbacks.add(identifier, fn)
}

// onConnect sends notifications to listeners (registered in onConnectCallbacks
// or stateChanges chanel readers) when client connects.
func (s *Server) onConnect(identifier string) {
	if err := s.onConnectCallbacks.call(identifier); err != nil {
		s.log.Error("OnConnect: error calling callback for %q: %s", identifier, err)
	}

	s.changeState(identifier, ClientConnected, nil)
}

// OnDisconnect calls the function when the client connected with the
// associated identifier disconnects from the server.
// After a client is disconnected, the associated function
// is also removed and needs to be added again.
func (s *Server) OnDisconnect(identifier string, fn func() error) {
	s.onDisconnectCallbacks.add(identifier, fn)
}

// onDisconnect sends notifications to listeners (registered in onDisconnectCallbacks
// or stateChanges chanel readers) when client disconnects.
func (s *Server) onDisconnect(identifier string, err error) {
	if err := s.onDisconnectCallbacks.call(identifier); err != nil {
		s.log.Error("OnDisconnect: error calling callback for %q: %s", identifier, err)
	}

	s.changeState(identifier, ClientClosed, err)
}

func (s *Server) changeState(identifier string, state ClientState, err error) (prev ClientState) {
	s.statesMu.Lock()
	defer s.statesMu.Unlock()

	prev = s.states[identifier]
	s.states[identifier] = state

	if s.stateCh != nil {
		change := &ClientStateChange{
			Identifier: identifier,
			Previous:   prev,
			Current:    state,
			Error:      err,
		}

		select {
		case s.stateCh <- change:
		default:
			s.log.Warning("Dropping state change due to slow reader: %s", change)
		}
	}

	return prev
}

// AddHost adds the given virtual host and maps it to the identifier.
func (s *Server) AddHost(host, identifier string) {
	s.virtualHosts.AddHost(host, identifier)
}

// DeleteHost deletes the given virtual host. Once removed any request to this
// host is denied.
func (s *Server) DeleteHost(host string) {
	s.virtualHosts.DeleteHost(host)
}

// AddAddr starts accepting connections on listener l, routing every connection
// to a tunnel client given by the identifier.
//
// When ip parameter is nil, all connections accepted from the listener are
// routed to the tunnel client specified by the identifier (port-based routing).
//
// When ip parameter is non-nil, only those connections are routed whose local
// address matches the specified ip (ip-based routing).
//
// If l listens on multiple interfaces it's desirable to call AddAddr multiple
// times with the same l value but different ip one.
func (s *Server) AddAddr(l net.Listener, ip net.IP, identifier string) {
	s.virtualAddrs.Add(l, ip, identifier)
}

// DeleteAddr stops listening for connections on the given listener.
//
// Upon return no more connections will be tunneled, but as the method does not
// close the listener, so any ongoing connection won't get interrupted.
func (s *Server) DeleteAddr(l net.Listener, ip net.IP) {
	s.virtualAddrs.Delete(l, ip)
}

func (s *Server) getIdentifier(host string) (string, bool) {
	identifier, ok := s.virtualHosts.GetIdentifier(host)
	return identifier, ok
}

func (s *Server) getHost(identifier string) (string, bool) {
	host, ok := s.virtualHosts.GetHost(identifier)
	return host, ok
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

func (s *Server) getSession(identifier string) (*yamux.Session, error) {
	s.sessionsMu.Lock()
	session, ok := s.sessions[identifier]
	s.sessionsMu.Unlock()

	if !ok {
		return nil, fmt.Errorf("no session available for identifier: '%s'", identifier)
	}

	return session, nil
}

func (s *Server) addSession(identifier string, session *yamux.Session) {
	s.sessionsMu.Lock()
	s.sessions[identifier] = session
	s.sessionsMu.Unlock()
}

func (s *Server) deleteSession(identifier string) {
	s.sessionsMu.Lock()
	defer s.sessionsMu.Unlock()

	session, ok := s.sessions[identifier]

	if !ok {
		return // nothing to delete
	}

	if session != nil {
		session.GoAway() // don't accept any new connection
		session.Close()
	}

	delete(s.sessions, identifier)
}

func copyHeader(dst, src http.Header) {
	for k, v := range src {
		vv := make([]string, len(v))
		copy(vv, v)
		dst[k] = vv
	}
}

// checkConnect checks whether the incoming request is HTTP CONNECT method.
func (s *Server) checkConnect(fn func(w http.ResponseWriter, r *http.Request) error) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != "CONNECT" {
			http.Error(w, "405 must CONNECT\n", http.StatusMethodNotAllowed)
			return
		}

		if err := fn(w, r); err != nil {
			s.log.Error("Handler err: %v", err.Error())

			if identifier := r.Header.Get(proto.ClientIdentifierHeader); identifier != "" {
				s.onDisconnect(identifier, err)
			}

			http.Error(w, err.Error(), 502)
		}
	})
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

func isWebsocketConn(r *http.Request) bool {
	return r.Method == "GET" && headerContains(r.Header["Connection"], "upgrade") &&
		headerContains(r.Header["Upgrade"], "websocket")
}

// headerContains is a copy of tokenListContainsValue from gorilla/websocket/util.go
func headerContains(header []string, value string) bool {
	for _, h := range header {
		for _, v := range strings.Split(h, ",") {
			if strings.EqualFold(strings.TrimSpace(v), value) {
				return true
			}
		}
	}

	return false
}

func nonil(err ...error) error {
	for _, e := range err {
		if e != nil {
			return e
		}
	}

	return nil
}

func newLogger(name string, debug bool) logging.Logger {
	log := logging.NewLogger(name)
	logHandler := logging.NewWriterHandler(os.Stderr)
	logHandler.Colorize = true
	log.SetHandler(logHandler)

	if debug {
		log.SetLevel(logging.DEBUG)
		logHandler.SetLevel(logging.DEBUG)
	}

	return log
}
