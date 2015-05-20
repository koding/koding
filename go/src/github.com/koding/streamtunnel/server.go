package streamtunnel

import (
	"bufio"
	"errors"
	"fmt"
	"io"
	"log"
	"net"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/hashicorp/yamux"
)

type Server struct {
	// pending contains the channel that is associated with each new tunnel request
	pending   map[string]chan net.Conn
	pendingMu sync.Mutex // protects the pending map

	// sessions contains a session per virtual host. Sessions provides
	// multiplexing over one connection
	sessions   map[string]*yamux.Session
	sessionsMu sync.Mutex // protects the sessions map

	// virtualHosts is used to map public hosts to remote clients
	virtualHosts *virtualHosts
}

func NewServer() *Server {
	s := &Server{
		pending:      make(map[string]chan net.Conn),
		sessions:     make(map[string]*yamux.Session),
		virtualHosts: newVirtualHosts(),
	}

	return s
}

// ServeHTTP is a tunnel that creates an http/websocket tunnel between a
// public connection and the client connection.
func (s *Server) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if err := s.HandleHTTP(w, r); err != nil {
		http.Error(w, err.Error(), 502)
		return
	}
}

func (s *Server) HandleHTTP(w http.ResponseWriter, r *http.Request) error {
	host := strings.ToLower(r.Host)
	if host == "" {
		return errors.New("request host is empty")
	}

	s.sessionsMu.Lock()
	session, ok := s.sessions[host]
	s.sessionsMu.Unlock()
	if !ok {
		return fmt.Errorf("no session available for '%s'", host)
	}

	conn, err := session.Accept()
	if err != nil {
		return err
	}

	if err := r.Write(conn); err != nil {
		return err
	}

	resp, err := http.ReadResponse(bufio.NewReader(conn), r)
	if err != nil {
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

// tunnelHandler is used to capture incoming tunnel connect requests into raw
// tunnel TCP connections.
func (s *Server) tunnelHandler(w http.ResponseWriter, r *http.Request) error {
	identifier := r.Header.Get(XKTunnelIdentifier)
	log.Printf("tunnel with identifier %s\n", identifier)

	hj, ok := w.(http.Hijacker)
	if !ok {
		return errors.New("webserver doesn't support hijacking")
	}

	conn, _, err := hj.Hijack()
	if err != nil {
		return fmt.Errorf("hijack not possible %s", err)
	}

	host, ok := s.GetHost(identifier)
	if !ok {
		return fmt.Errorf("no host associated for identifier %s. please use server.AddHost()", identifier)
	}

	io.WriteString(conn, "HTTP/1.1 "+Connected+"\n\n")
	conn.SetDeadline(time.Time{})

	session, err := yamux.Server(conn, yamux.DefaultConfig())
	if err != nil {
		return err
	}

	s.sessionsMu.Lock()
	s.sessions[host] = session
	s.sessionsMu.Unlock()

	return nil
}

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

func join(local, remote io.ReadWriteCloser) chan error {
	errc := make(chan error, 2)

	copy := func(dst io.Writer, src io.Reader) {
		_, err := io.Copy(dst, src)
		errc <- err
	}

	go copy(local, remote)
	go copy(remote, local)

	return errc
}

func copyHeader(dst, src http.Header) {
	for k, vv := range src {
		for _, v := range vv {
			dst.Add(k, v)
		}
	}
}
