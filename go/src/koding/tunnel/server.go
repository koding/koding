package tunnel

import (
	"fmt"
	"io"
	"log"
	"net"
	"net/http"
	"net/http/httputil"
	"strings"
	"sync"
	"time"
)

type Server struct {
	tunnels *Tunnels
	sync.Mutex
}

func NewServer() *Server {
	s := &Server{tunnels: NewTunnels()}
	http.HandleFunc(RegisterPath, s.registerHandler)
	return s
}

func (s *Server) registerHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Println("register Handler invoked", r.URL.String())
	if r.Method != "CONNECT" {
		w.Header().Set("Content-Type", "text/plain; charset=utf-8")
		w.WriteHeader(http.StatusMethodNotAllowed)
		io.WriteString(w, "405 must CONNECT\n")
		return
	}

	conn, _, err := w.(http.Hijacker).Hijack()
	if err != nil {
		log.Println("rpc hijacking ", r.RemoteAddr, ": ", err.Error())
		return
	}

	io.WriteString(conn, "HTTP/1.1 "+Connected+"\n\n")
	s.tunnels.addTunnel("127.0.0.1:7000", NewTunnel(conn))
}

func (s *Server) TunnelHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Println("tunnel Handler invoked", r.URL.String())
	host := strings.ToLower(r.Host)

	s.Lock()
	defer s.Unlock()

	tunnel, ok := s.tunnels.getTunnel(host)
	if !ok {
		err := fmt.Sprintf("no such tunnel: %s", host)
		http.Error(w, err, 404)
		return
	}

	resp, err := tunnel.clientConn.Do(r)
	if err != nil {
		errString := fmt.Sprintf("clientConn req %s", err.Error())
		http.Error(w, errString, 404)
		return
	}
	defer resp.Body.Close()

	copyHeader(w.Header(), resp.Header)
	w.WriteHeader(resp.StatusCode)

	io.Copy(w, resp.Body)
}

type Tunnel struct {
	clientConn *httputil.ClientConn
	start      time.Time
}

func NewTunnel(conn net.Conn) *Tunnel {
	return &Tunnel{
		clientConn: httputil.NewClientConn(conn, nil),
		start:      time.Now(),
	}
}

type Tunnels struct {
	sync.Mutex
	tunnels map[string]*Tunnel
}

func NewTunnels() *Tunnels {
	return &Tunnels{
		tunnels: make(map[string]*Tunnel),
	}
}

func (t *Tunnels) getTunnel(url string) (*Tunnel, bool) {
	t.Lock()
	defer t.Unlock()

	tunnel, ok := t.tunnels[url]
	return tunnel, ok
}

func (t *Tunnels) addTunnel(url string, tunnel *Tunnel) {
	t.Lock()
	defer t.Unlock()

	t.tunnels[url] = tunnel
}

func copyHeader(dst, src http.Header) {
	for k, vv := range src {
		for _, v := range vv {
			dst.Add(k, v)
		}
	}
}

// IMPORTANT: left for future reference, this is doing bare tcp connection, need some work
// func (s *Server) proxyHandler(w http.ResponseWriter, r *http.Request) {
// 	fmt.Println("proxy Handler invoked", r.URL.String())
// 	host := strings.ToLower(r.Host)
// 	tunnel, ok := s.tunnels.getTunnel(host)
// 	if !ok {
// 		err := fmt.Sprintf("no such tunnel: %s", host)
// 		http.Error(w, err, 404)
// 		return
// 	}

// 	// write back initial public request of client to the tunnelClient
// 	err := r.Write(tunnel.conn)
// 	if err != nil {
// 		fmt.Printf("error copying request to target: %v", err)
// 		http.NotFound(w, r)
// 		return
// 	}

// 	publicConn, _, err := w.(http.Hijacker).Hijack()
// 	if err != nil {
// 		log.Println("rpc hijacking ", r.RemoteAddr, ": ", err.Error())
// 		return
// 	}

// 	errc := make(chan error, 2)
// 	cp := func(dst io.Writer, src io.Reader) {
// 		count++
// 		_, err := io.Copy(dst, src)
// 		fmt.Println("err copy", count, err)
// 		errc <- err
// 	}

// 	tunnel.conn.SetDeadline(time.Time{})

// 	go cp(publicConn, tunnel.conn)
// 	go cp(tunnel.conn, publicConn)
// 	<-errc

// 	join.Join(publicConn, tunnel.conn)
// }
