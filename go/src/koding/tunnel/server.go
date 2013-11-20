package tunnel

import (
	"bufio"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"strings"
	"sync"
	"time"
)

// Server satisfies the http.Handler interface. It is responsible of tracking
// tunnels and creating tunnels between remote and local connection.
type Server struct {
	tunnels *Tunnels
	sync.Mutex
}

type Clients struct {
}

func NewServer() *Server {
	s := &Server{
		tunnels: NewTunnels(),
	}

	http.HandleFunc(ControlPath, s.controlHandler)
	http.HandleFunc(TunnelPath, s.tunnelHandler)
	return s
}

func (s *Server) tunnelHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Println("tunnel Handler invoked", r.URL.String())
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

	s.AddTunnel("127.0.0.1:7000", NewTunnel(conn))
}

// controlHandler is used to register tunnel clients.
func (s *Server) controlHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Println("control asdksa Handler invoked", r.URL.String())
	if r.Method != "CONNECT" {
		fmt.Println("asdkasjdkljsakl")
		fmt.Println("r.Method", r.Method)
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

	d := json.NewDecoder(conn)
	e := json.NewEncoder(conn)

	for {
		var msg ClientMsg
		err := d.Decode(&msg)
		if err != nil {
			fmt.Println("decode", err)
			return
		}

		if msg.Action == "tunnel" {
			msg := &ServerMsg{Action: "allowed"}
			err := e.Encode(msg)
			if err != nil {
				fmt.Println("encode", err)
				return
			}

		}

		fmt.Println("msg from client", msg)
	}
}

// ServeHTTP is a tunnel that creates an http/websocket tunnel between a
// public connection and the client connection.
func (s *Server) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if isWebsocket(r) {
		s.websocketHandleFunc(w, r)
		return
	}

	log.Println("http handler invoked", r.URL.String())
	host := strings.ToLower(r.Host)

	s.Lock()
	defer s.Unlock()

	tunnel, ok := s.GetTunnel(host)
	if !ok {
		err := fmt.Sprintf("no such tunnel: %s", host)
		http.Error(w, err, 404)
		return
	}

	err := r.Write(tunnel.conn)
	if err != nil {
		err := fmt.Sprintf("write to tunnel %s", err)
		http.Error(w, err, 404)
		return
	}

	resp, err := http.ReadResponse(bufio.NewReader(tunnel.conn), r)
	if err != nil {
		errString := fmt.Sprintf("read from tunnel.con %s", err.Error())
		http.Error(w, errString, 404)
		return
	}

	defer resp.Body.Close()

	copyHeader(w.Header(), resp.Header)
	w.WriteHeader(resp.StatusCode)

	io.Copy(w, resp.Body)
}

func (s *Server) websocketHandleFunc(w http.ResponseWriter, r *http.Request) {
	log.Println("websocket handler invoked", r.URL.String())

	host := strings.ToLower(r.Host)
	tunnel, ok := s.GetTunnel(host)
	if !ok {
		err := fmt.Sprintf("no such tunnel: %s", host)
		http.Error(w, err, 404)
		return
	}

	err := r.Write(tunnel.conn)
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

	err = <-join(tunnel.conn, publicConn)
	log.Println(err)
}

func (s *Server) AddTunnel(url string, tunnel *Tunnel) {
	s.tunnels.addTunnel(url, tunnel)
}

func (s *Server) GetTunnel(url string) (*Tunnel, bool) {
	return s.tunnels.getTunnel(url)
}
