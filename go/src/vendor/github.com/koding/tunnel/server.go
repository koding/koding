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

	"github.com/hashicorp/yamux"
	"github.com/koding/logging"
)

var (
	errNoClientSession = errors.New("no client session established")
	defaultTimeout     = 10 * time.Second
)

// Server is responsible for proxying public connections to the client over a
// tunnel connection. It also listens to control messages from the client.
type Server struct {
	// pending contains the channel that is associated with each new tunnel request
	pending   map[string]chan net.Conn
	pendingMu sync.Mutex // protects the pending map

	// sessions contains a session per virtual host. Sessions provides
	// multiplexing over one connection
	sessions   map[string]*yamux.Session
	sessionsMu sync.Mutex // protects the sessions map

	// controls contains the control connection from the client to the server
	controls *controls

	// virtualHosts is used to map public hosts to remote clients
	virtualHosts vhostStorage

	// virtualAddrs
	virtualAddrs *vaddrStorage

	// connCh is used to publish accepted connections for tcp tunnels.
	connCh chan net.Conn

	// onConnect contains client callbacks called when control
	// session is established for a client with given identifier
	onConnect *callbacks

	// onDisconnect contains the onDisconnect for each map
	onDisconnect *callbacks

	// httpDirector is provided by ServerConfig, if not nil decorates http requests
	// before forwarding them to client.
	httpDirector func(*http.Request)

	// yamuxConfig is passed to new yamux.Session's
	yamuxConfig *yamux.Config

	log logging.Logger
}

// ServerConfig defines the configuration for the Server
type ServerConfig struct {
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
		pending:      make(map[string]chan net.Conn),
		sessions:     make(map[string]*yamux.Session),
		onConnect:    newCallbacks("OnConnect"),
		onDisconnect: newCallbacks("OnDisconnect"),
		virtualHosts: newVirtualHosts(),
		virtualAddrs: newVirtualAddrs(opts),
		controls:     newControls(),
		httpDirector: cfg.Director,
		yamuxConfig:  yamuxConfig,
		connCh:       connCh,
		log:          log,
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
	case controlPath:
		s.checkConnect(s.controlHandler).ServeHTTP(w, r)
		return
	}

	if err := s.handleHTTP(w, r); err != nil {
		if !strings.Contains(err.Error(), "no virtual host available") { // this one is outputted too much, unnecessarily
			s.log.Error("remote %s (%s): %s", r.RemoteAddr, r.RequestURI, err)
		}
		http.Error(w, err.Error(), 502)
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

	stream, err := s.dial(identifier, httpTransport, port)
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
		return errors.New("webserver doesn't support hijacking")
	}

	conn, _, err := hj.Hijack()
	if err != nil {
		return fmt.Errorf("hijack not possible: %s", err)
	}

	stream, err := s.dial(ident, wsTransport, port)
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

	stream, err := s.dial(ident, tcpTransport, port)
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

func (s *Server) dial(ident string, proto transportProtocol, port int) (net.Conn, error) {
	control, ok := s.getControl(ident)
	if !ok {
		return nil, errNoClientSession
	}

	session, err := s.getSession(ident)
	if err != nil {
		return nil, err
	}

	msg := controlMsg{
		Action:    requestClientSession,
		Protocol:  proto,
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
		s.deleteControl(ident)
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
	identifier := r.Header.Get(xKTunnelIdentifier)
	_, ok := s.getHost(identifier)
	if !ok {
		return fmt.Errorf("no host associated for identifier %s. please use server.AddHost()", identifier)
	}

	ct, ok := s.getControl(identifier)
	if ok {
		ct.Close()
		s.deleteControl(identifier)
		s.log.Warning("Control connection for '%s' already exists. This is a race condition and needs to be fixed on client implementation", identifier)
		return fmt.Errorf("control conn for %s already exist. \n", identifier)
	}

	s.log.Debug("Tunnel with identifier %s", identifier)

	hj, ok := w.(http.Hijacker)
	if !ok {
		return errors.New("webserver doesn't support hijacking")
	}

	conn, _, err := hj.Hijack()
	if err != nil {
		return fmt.Errorf("hijack not possible: %s", err)
	}

	if _, err := io.WriteString(conn, "HTTP/1.1 "+connected+"\n\n"); err != nil {
		return fmt.Errorf("error writing response: %s", err)
	}

	conn.SetDeadline(time.Time{})

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
	buf := make([]byte, len(ctHandshakeRequest))
	if _, err := stream.Read(buf); err != nil {
		return err
	}

	if string(buf) != ctHandshakeRequest {
		return fmt.Errorf("handshake aborted. got: %s", string(buf))
	}

	if _, err := stream.Write([]byte(ctHandshakeResponse)); err != nil {
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
	if err := s.onConnect.call(ct.identifier); err != nil {
		s.log.Error("OnConnect: error calling callback for %q: %s", ct.identifier, err)
	}

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
			if err := s.onDisconnect.call(ct.identifier); err != nil {
				s.log.Error("OnDisconnect: error calling callback for %q: %s", ct.identifier, err)
			}

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
// when it establishes a control sessin.
func (s *Server) OnConnect(identifier string, fn func() error) {
	s.onConnect.add(identifier, fn)
}

// OnDisconnect calls the function when the client connected with the
// associated identifier disconnects from the server. After a client is
// disconnected, the associated function is alro removed and needs to be
// readded again.
func (s *Server) OnDisconnect(identifier string, fn func() error) {
	s.onDisconnect.add(identifier, fn)
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

// checkConnect checks wether the incoming request is HTTP CONNECT method. If
func (s *Server) checkConnect(fn func(w http.ResponseWriter, r *http.Request) error) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != "CONNECT" {
			http.Error(w, "405 must CONNECT\n", http.StatusMethodNotAllowed)
			return
		}

		err := fn(w, r)
		if err != nil {
			s.log.Error("Handler err: %v", err.Error())
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
