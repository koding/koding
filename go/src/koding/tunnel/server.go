package tunnel

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
)

// Server satisfies the http.Handler interface. It is responsible of tracking
// tunnels and creating tunnels between remote and local connection.
type Server struct {
	// protects the following fields
	mu sync.Mutex

	// pending contains the channel that is associated with each new tunnel request
	pending map[string]chan *tunnel

	// httpTunnels is used to store established tunnel connections used for
	// http. Currently for each virtual host one single http connection is
	// stored.
	httpTunnels *tunnels

	// controls contains the control connection from the client to the server
	controls *controls

	// virtualHosts is used to map public hosts to remote clients
	virtualHosts *virtualHosts
}

// NewServer returns a new Server instance. It registers by default two new
// http handlers to the default.Mux which is uses for establishing control
// connections and creating tunnels.
func NewServer() *Server {
	s := &Server{
		pending:      make(map[string]chan *tunnel),
		httpTunnels:  newTunnels(),
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
	log.Println("--- tunnel Handler invoked", r.URL.String())
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
	log.Printf("we have a new tunnel. protocol %s, tunnelID %s and username %s\n",
		protocol, tunnelID, username)

	s.mu.Lock()
	defer s.mu.Unlock()

	tunnelRequester, ok := s.pending[tunnelID]
	if !ok {
		log.Println("tunnelID channel does not exist")
		return
	}

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
	log.Println("--- control Handler invoked", r.URL.String())
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
		s.deleteTunnel(host)
	}()

	log.Println("control connection has been established for", username)
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

	log.Println("http handler invoked", r.Host, r.URL.String())
	host := strings.ToLower(r.Host)

	tunnelConn, err := s.httpTunnelConn(host)
	if err != nil {
		log.Println(err)
		http.Error(w, err.Error(), 404)
		return
	}

	s.mu.Lock()
	defer s.mu.Unlock()

	err = r.Write(tunnelConn)
	if err != nil {
		err := fmt.Sprintf("write to tunnel %s", err)
		log.Println(err)
		http.Error(w, err, 404)
		return
	}

	resp, err := http.ReadResponse(bufio.NewReader(tunnelConn), r)
	if err != nil {
		err := fmt.Sprintf("read from tunnel.con %s", err.Error())
		log.Println(err)
		http.Error(w, err, 404)
		return
	}
	defer resp.Body.Close()

	copyHeader(w.Header(), resp.Header)
	w.WriteHeader(resp.StatusCode)

	io.Copy(w, resp.Body)
}

func (s *Server) httpTunnelConn(host string) (net.Conn, error) {
	// for http one single conn is enough
	var err error
	tunnel, ok := s.getTunnel(host)
	if !ok {
		// get a tunnel from client
		tunnel, err = s.requestTunnel("http", host)
		if err != nil {
			return nil, err
		}

		// delete the tunnel if there is a disconnection this will trigger
		// another requestTunnel call on the next http connection.
		tunnel.OnDisconnect(func() { s.deleteTunnel(host) })

		s.addTunnel(host, tunnel)
	}

	return tunnel, nil
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

	log.Println("write request back to websocket")
	err = r.Write(tunnelConn)
	if err != nil {
		err := fmt.Sprintf("write to tunnel %s", err)
		http.Error(w, err, 404)
		return
	}

	log.Println("get publicconn hijack")
	publicConn, _, err := w.(http.Hijacker).Hijack()
	if err != nil {
		log.Println("websocket hijacking ", err)
		return
	}
	defer publicConn.Close()

	log.Println("copy websocket.......")
	err = <-join(tunnelConn, publicConn)
	log.Println(err)
}

func (s *Server) websocketTunnelConn(host string) (net.Conn, error) {
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
	log.Printf("no tunnel available for (%s) %s. request one", protocol, host)

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

	log.Printf("got control for %s, preparing tunnel request", host)

	// create an unique id to used with that tunnel
	tunnelID := randomID(32)

	// request a new http tunnel
	msg := ServerMsg{
		Protocol: protocol,
		TunnelID: tunnelID,
		Username: username,
		Host:     host,
	}

	control.send(msg)

	// now wait until our tunnel is established. if the tunnel has the
	// right ID it will send a message to this channel, which releases the
	// blocking channel. If we don't get it in 10 seconds we will timeout
	log.Printf("tunnel request send for %s, waiting for tunnel...\n", host)
	s.pending[tunnelID] = make(chan *tunnel)

	// remove and close it because we don't need it anymore
	defer func() {
		close(s.pending[tunnelID])
		delete(s.pending, tunnelID)
	}()

	select {
	case tunnel := <-s.pending[tunnelID]:
		return tunnel, nil
	case <-time.After(time.Second * 10):
		return nil, errors.New("timeout")
	}
}

func (s *Server) getTunnel(host string) (*tunnel, bool) {
	tunnel, ok := s.httpTunnels.getTunnel(host)
	return tunnel, ok
}

func (s *Server) addTunnel(host string, tunnel *tunnel) {
	s.httpTunnels.addTunnel(host, tunnel)
}

func (s *Server) deleteTunnel(host string) {
	s.httpTunnels.deleteTunnel(host)
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
