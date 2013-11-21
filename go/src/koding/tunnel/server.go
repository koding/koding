package tunnel

import (
	"bufio"
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
	tunnels    map[string]*Tunnels
	tunnelChan map[string]chan bool
	controls   *Controls
	sync.Mutex
}

func NewServer() *Server {
	s := &Server{
		tunnels:    make(map[string]*Tunnels),
		tunnelChan: make(map[string]chan bool),
		controls:   NewControls(),
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

	// set by control channel
	protocol := r.Header.Get("protocol")
	tunnelID := r.Header.Get("id")

	done, ok := s.tunnelChan[tunnelID]
	if !ok {
		log.Println("tunnelID channel does not exist")
		return
	}

	host := strings.ToLower(r.Host)

	tunnels, ok := s.GetTunnels(host)
	if !ok {
		// first time, create it
		tunnels = NewTunnels()
	}

	tunnels.addTunnel(protocol, NewTunnel(conn))
	s.AddTunnels(host, tunnels)

	// let any channel associated with this tunnel let know that we passed everything and
	// that our tunnel is now ready
	done <- true
}

// controlHandler is used to register tunnel clients.
func (s *Server) controlHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Println("control Handler invoked", r.URL.String())
	if r.Method != "CONNECT" {
		w.Header().Set("Content-Type", "text/plain; charset=utf-8")
		w.WriteHeader(http.StatusMethodNotAllowed)
		io.WriteString(w, "405 must CONNECT\n")
		return
	}

	username := r.Header.Get("id")

	_, ok := s.GetControl(username)
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
	control := NewControl(conn)
	s.AddControl(username, control)

	// delete and close the conn when the control connection is being closed
	defer func() {
		control.Close()
		s.DeleteControl(username)
	}()

	// blocking function
	control.run()
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

	tunnels, ok := s.GetTunnels(host)
	if !ok {
		// there is no tunnel available, go and get one via our control conn
		control, ok := s.GetControl(host)
		if !ok {
			fmt.Println("no control availabiel for", host)
			return
		}

		// create an unique id to used with that tunnel
		tunnelID := "1234567890"

		// request a new http tunnel
		control.SendMsg("http", tunnelID)

		// now wait until our tunnel is estabhlised if the tunnel has the
		// right ID it will send a message to this channel, which releases the
		// blocking channel. First we create the channel for this id.
		s.tunnelChan[tunnelID] = make(chan bool)

		// then we wait, until we got our done channel
		<-s.tunnelChan[tunnelID]

		// remove it because we don't need it anymore
		delete(s.tunnelChan, tunnelID)
	}

	// for http one single conn is enough
	tunnel, ok := tunnels.getTunnel("http")
	if !ok {
		err := fmt.Sprintf("no http tunnel: %s", host)
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
	tunnels, ok := s.GetTunnels(host)
	if !ok {
		err := fmt.Sprintf("no such tunnel: %s", host)
		http.Error(w, err, 404)
		return
	}

	tunnel, ok := tunnels.getTunnel("websocket")
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

func (s *Server) GetTunnels(username string) (*Tunnels, bool) {
	s.Lock()
	defer s.Unlock()

	tunnels, ok := s.tunnels[username]
	return tunnels, ok
}

func (s *Server) AddTunnels(username string, tunnels *Tunnels) {
	s.Lock()
	defer s.Unlock()

	s.tunnels[username] = tunnels
}

func (s *Server) AddControl(username string, conn *Control) {
	s.controls.addControl(username, conn)
}

func (s *Server) GetControl(username string) (*Control, bool) {
	return s.controls.getControl(username)
}

func (s *Server) DeleteControl(username string) {
	s.controls.deleteControl(username)
}
