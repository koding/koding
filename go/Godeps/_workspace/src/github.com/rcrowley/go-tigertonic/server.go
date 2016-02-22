package tigertonic

import (
	"crypto/tls"
	"crypto/x509"
	"io/ioutil"
	"net"
	"net/http"
	"sync"
	"time"
)

// Server is an http.Server with better defaults and built-in graceful stop.
type Server struct {
	http.Server
	ch        chan<- struct{}
	conns     map[string]net.Conn
	listeners []net.Listener
	mu        sync.Mutex // guards conns and listeners
	wg        sync.WaitGroup
}

// NewServer returns an http.Server with better defaults and built-in graceful
// stop.
func NewServer(addr string, handler http.Handler) *Server {
	ch := make(chan struct{})
	s := &Server{
		Server: http.Server{
			Addr: addr,
			Handler: &serverHandler{
				Handler: handler,
			},
			MaxHeaderBytes: 4096,
			ReadTimeout:    60e9, // These are absolute times which must be
			WriteTimeout:   60e9, // longer than the longest {up,down}load.
		},
		ch:    ch,
		conns: make(map[string]net.Conn),
	}
	s.ConnState = func(conn net.Conn, state http.ConnState) {
		switch state {
		case http.StateNew:
			s.wg.Add(1)
		case http.StateActive:
			s.mu.Lock()
			delete(s.conns, conn.LocalAddr().String())
			s.mu.Unlock()
		case http.StateIdle:
			select {
			case <-ch:
				//conn.SetReadDeadline(time.Now().Add(500 * time.Millisecond)) // Doesn't work but seems like the right idea.
				conn.Close()
			default:
				s.mu.Lock()
				s.conns[conn.LocalAddr().String()] = conn
				s.mu.Unlock()
			}
		case http.StateHijacked, http.StateClosed:
			s.wg.Done()
		}
	}
	return s
}

// NewTLSServer returns an http.Server with better defaults configured to use
// the certificate and private key files.
func NewTLSServer(
	addr, cert, key string,
	handler http.Handler,
) (*Server, error) {
	s := NewServer(addr, handler)
	return s, s.TLS(cert, key)
}

// CA overrides the certificate authority on the Server's TLSConfig field.
func (s *Server) CA(ca string) error {
	certPool := x509.NewCertPool()
	buf, err := ioutil.ReadFile(ca)
	if nil != err {
		return err
	}
	certPool.AppendCertsFromPEM(buf)
	s.tlsConfig()
	s.TLSConfig.RootCAs = certPool
	return nil
}

// ClientCA configures the CA pool for verifying client side certificates.
func (s *Server) ClientCA(ca string) error {
	certPool := x509.NewCertPool()
	buf, err := ioutil.ReadFile(ca)
	if nil != err {
		return err
	}
	certPool.AppendCertsFromPEM(buf)
	s.tlsConfig()
	s.TLSConfig.ClientAuth = tls.RequireAndVerifyClientCert
	s.TLSConfig.ClientCAs = certPool
	return nil
}

// Close closes all the net.Listeners passed to Serve (even via ListenAndServe)
// and signals open connections to close at their earliest convenience.  That
// is either after responding to the current request or after a short grace
// period for idle keepalive connections.  Close blocks until all connections
// have been closed.
func (s *Server) Close() error {
	close(s.ch)
	s.SetKeepAlivesEnabled(false)
	s.mu.Lock()
	for _, l := range s.listeners {
		if err := l.Close(); nil != err {
			return err
		}
	}
	s.listeners = nil
	t := time.Now().Add(500 * time.Millisecond)
	for _, c := range s.conns {
		c.SetReadDeadline(t)
	}
	s.conns = make(map[string]net.Conn)
	s.mu.Unlock()
	s.wg.Wait()
	return nil
}

// ListenAndServe calls net.Listen with s.Addr and then calls s.Serve.
func (s *Server) ListenAndServe() error {
	addr := s.Addr
	if "" == addr {
		if nil == s.TLSConfig {
			addr = ":http"
		} else {
			addr = ":https"
		}
	}
	l, err := net.Listen("tcp", addr)
	if nil != err {
		return err
	}
	if nil != s.TLSConfig {
		l = tls.NewListener(l, s.TLSConfig)
	}
	return s.Serve(l)
}

// ListenAndServeTLS calls s.TLS with the given certificate and private key
// files and then calls s.ListenAndServe.
func (s *Server) ListenAndServeTLS(cert, key string) error {
	s.TLS(cert, key)
	return s.ListenAndServe()
}

// Serve behaves like http.Server.Serve with the added option to stop the
// Server gracefully with the s.Close method.
func (s *Server) Serve(l net.Listener) error {
	s.mu.Lock()
	s.listeners = append(s.listeners, l)
	s.mu.Unlock()
	return s.Server.Serve(l)
}

// TLS configures this Server to be a TLS server using the given certificate
// and private key files.
func (s *Server) TLS(cert, key string) error {
	c, err := tls.LoadX509KeyPair(cert, key)
	if nil != err {
		return err
	}
	s.tlsConfig()
	s.TLSConfig.Certificates = []tls.Certificate{c}
	return nil
}

func (s *Server) tlsConfig() {
	if nil == s.TLSConfig {
		s.TLSConfig = &tls.Config{
			NextProtos: []string{"http/1.1"},
		}
	}
}

type serverHandler struct {
	http.Handler
}

func (h *serverHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	// r.Header.Set("Host", r.Host) // Should I?
	r.URL.Host = r.Host
	if nil != r.TLS {
		r.URL.Scheme = "https"
	} else {
		r.URL.Scheme = "http"
	}
	h.Handler.ServeHTTP(w, r)
}
