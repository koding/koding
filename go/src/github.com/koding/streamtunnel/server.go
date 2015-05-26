package streamtunnel

import (
	"bufio"
	"errors"
	"fmt"
	"io"
	"net"
	"net/http"
	"os"
	"path"
	"strings"
	"sync"
	"time"

	"github.com/hashicorp/yamux"
	"github.com/koding/logging"
)

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

	// yamuxConfig is passed to new yamux.Session's
	yamuxConfig *yamux.Config

	log logging.Logger
}

// ServerConfig defines the configuration for the Server
type ServerConfig struct {
	// Debug enables debug mode, enable only if you want to debug the server
	Debug bool

	// Log defines the logger. If nil a default logging.Logger is used.
	Log logging.Logger

	// YamuxConfig defines the config which passed to every new yamux.Session. If nil
	// yamux.DefaultConfig() is used.
	YamuxConfig *yamux.Config
}

func NewServer(cfg *ServerConfig) *Server {
	yamuxConfig := yamux.DefaultConfig()
	if cfg.YamuxConfig != nil {
		if err := yamux.VerifyConfig(cfg.YamuxConfig); err != nil {
			fmt.Fprintf(os.Stderr, err.Error())
			os.Exit(1)
		}

		yamuxConfig = cfg.YamuxConfig
	}

	log := newLogger("streamtunnel-server", cfg.Debug)
	if cfg.Log != nil {
		log = cfg.Log
	}

	s := &Server{
		pending:      make(map[string]chan net.Conn),
		sessions:     make(map[string]*yamux.Session),
		virtualHosts: newVirtualHosts(),
		controls:     newControls(),
		yamuxConfig:  yamuxConfig,
		log:          log,
	}

	http.Handle(ControlPath, s.checkConnect(s.ControlHandler))
	return s
}

// ServeHTTP is a tunnel that creates an http/websocket tunnel between a
// public connection and the client connection.
func (s *Server) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	// if the user didn't add the control and tunnel handler manually, we'll
	// going to infer and call the respective path handlers.
	switch path.Clean(r.URL.Path) + "/" {
	case ControlPath:
		s.checkConnect(s.ControlHandler).ServeHTTP(w, r)
		return
	}

	if err := s.HandleHTTP(w, r); err != nil {
		http.Error(w, err.Error(), 502)
		return
	}
}

func (s *Server) HandleHTTP(w http.ResponseWriter, r *http.Request) error {
	s.log.Debug("HandleHTTP request:")
	s.log.Debug("%v", r)

	host := strings.ToLower(r.Host)
	if host == "" {
		return errors.New("request host is empty")
	}

	// get the identifier associated with this host
	identifier, ok := s.GetIdentifier(host)
	if !ok {
		return fmt.Errorf("no virtual host available for %s", host)
	}

	// then grab the control connection that is associated with this identifier
	control, ok := s.getControl(identifier)
	if !ok {
		return fmt.Errorf("no control available for %s", host)
	}

	session, err := s.getSession(identifier)
	if err != nil {
		return err
	}

	// if someoone hits foo.example.com:8080, this should be proxied to
	// localhost:8080, so send the port to the client so it knows how to proxy
	// correctly. If no port is available, it's up to client how to intepret it
	_, port, _ := net.SplitHostPort(r.Host)
	msg := ControlMsg{
		Action:    RequestClientSession,
		Protocol:  HTTPTransport,
		LocalPort: port,
	}

	// ask client to open a session to us, so we can accept it
	if err := control.send(msg); err != nil {
		return err
	}

	var stream net.Conn
	defer func() {
		if stream != nil {
			stream.Close()
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

	if err := r.Write(stream); err != nil {
		return err
	}

	resp, err := http.ReadResponse(bufio.NewReader(stream), r)
	if err != nil {
		if resp.Body == nil {
			resp.Body.Close()
		}
		return fmt.Errorf("read from tunnel: %s", err.Error())
	}
	defer resp.Body.Close()

	copyHeader(w.Header(), resp.Header)
	w.WriteHeader(resp.StatusCode)
	if _, err := io.Copy(w, resp.Body); err != nil {
		return err
	}

	return nil
}

// ControlHandler is used to capture incoming tunnel connect requests into raw
// tunnel TCP connections.
func (s *Server) ControlHandler(w http.ResponseWriter, r *http.Request) (ctErr error) {
	identifier := r.Header.Get(XKTunnelIdentifier)
	_, ok := s.GetHost(identifier)
	if !ok {
		return fmt.Errorf("no host associated for identifier %s. please use server.AddHost()", identifier)
	}

	ct, ok := s.getControl(identifier)
	if ok {
		ct.Close()
		s.log.Warning("Control connection for '%s' already exists. This is a race condition and needs to be fixed on client implementation", identifier)
		return fmt.Errorf("control conn for %s already exist. \n", identifier)
	}

	s.log.Debug("tunnel with identifier %s", identifier)
	hj, ok := w.(http.Hijacker)
	if !ok {
		return errors.New("webserver doesn't support hijacking")
	}

	conn, _, err := hj.Hijack()
	if err != nil {
		return fmt.Errorf("hijack not possible %s", err)
	}

	io.WriteString(conn, "HTTP/1.1 "+Connected+"\n\n")

	conn.SetDeadline(time.Time{})

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

	return nil
}

// listenControl listens to messages coming from the client.
func (s *Server) listenControl(ct *control) {
	for {
		var msg map[string]interface{}
		err := ct.dec.Decode(&msg)
		if err != nil {
			ct.Close()
			s.deleteControl(ct.identifier)
			s.deleteSession(ct.identifier)
			s.log.Error("decode err: %s", err)
			return
		}

		// right now we don't do anything with the messages, but because the
		// underlying connection needs to establihsed, we know when we have
		// disconnection(above), so we can cleanup the connection.
		s.log.Debug("msg: %s", msg)
	}
}

func (s *Server) AddHost(host, identifier string) {
	s.virtualHosts.AddHost(host, identifier)
}

func (s *Server) DeleteHost(host string) {
	s.virtualHosts.DeleteHost(host)
}

func (s *Server) GetIdentifier(host string) (string, bool) {
	identifier, ok := s.virtualHosts.GetIdentifier(host)
	return identifier, ok
}

func (s *Server) GetHost(identifier string) (string, bool) {
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
	session, ok := s.sessions[identifier]
	s.sessionsMu.Unlock()

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
	for k, vv := range src {
		for _, v := range vv {
			dst.Add(k, v)
		}
	}
}

// checkConnect checks wether the incoming request is HTTP CONNECT method. If
func (s *Server) checkConnect(fn func(w http.ResponseWriter, r *http.Request) error) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != "CONNECT" {
			w.Header().Set("Content-Type", "text/plain; charset=utf-8")
			w.WriteHeader(http.StatusMethodNotAllowed)
			io.WriteString(w, "405 must CONNECT\n")
			return
		}

		err := fn(w, r)
		if err != nil {
			s.log.Error("Handler err: %v", err.Error())
			http.Error(w, err.Error(), 502)
		}
	})
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
