package main

import (
	"bufio"
	"fmt"
	"io"
	"koding/kites/tunnel/join"
	"koding/kites/tunnel/protocol"
	"log"
	"net"
	"net/http"
	"os"
	"strings"
	"sync"
	"time"
)

const (
	NotFound = `HTTP/1.1 404 Not Found
Content-Length: %d

Tunnel %s not found
`
	MustConnect = `HTTP/1.1 405 must CONNECT `
)

var serverAddr = "127.0.0.1:7000"

func init() {
	log.SetOutput(os.Stdout)
	log.SetPrefix("tunnel-server ")
	log.SetFlags(log.Lmicroseconds)
}

var tunnelHandler = NewTunnels()

func main() {

	// httpListener()

	http.HandleFunc(protocol.RegisterPath, registerHandler)
	http.HandleFunc("/", proxyHandler)

	log.Println(http.ListenAndServe(serverAddr, nil))
}

func proxyHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Println("proxy Handler invoked", r.URL.String())
	host := strings.ToLower(r.Host)
	tunnel, ok := tunnelHandler.getTunnel(host)
	if !ok {
		err := fmt.Sprintf("no such tunnel: %s", host)
		http.Error(w, err, 404)
		return
	}

	conn, _, err := w.(http.Hijacker).Hijack()
	if err != nil {
		log.Println("rpc hijacking ", r.RemoteAddr, ": ", err.Error())
		return
	}

	defer conn.Close()
	defer tunnel.clientConn.Close()

	// write back initial public request of client to the tunnelClient
	r.Write(tunnel.clientConn)
	if err != nil {
		fmt.Printf("error copying request to target: %v", err)
		http.NotFound(w, r)
		return
	}

	// tunnel.clientConn.Write([]byte("start_proxy"))
	// conn.Write([]byte("wait"))
	join.Join(conn, tunnel.clientConn)
}

func registerHandler(w http.ResponseWriter, r *http.Request) {
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
	conn.SetDeadline(time.Time{})

	io.WriteString(conn, "HTTP/1.1 "+protocol.Connected+"\n\n")
	tunnelHandler.addTunnel("127.0.0.1:7000", NewTunnel(conn))
}

func httpListener() {
	tcpAddr, _ := net.ResolveTCPAddr("tcp4", serverAddr)

	listener, err := net.ListenTCP("tcp", tcpAddr)
	if err != nil {
		log.Println("listen server err", err)
	}

	log.Println("server started", listener.Addr())

	for {
		c, err := listener.AcceptTCP()
		if err != nil {
			log.Println("accept err: %s", err)
			continue
		}

		log.Println("got a new conn", c.RemoteAddr().String())

		go serve(c)
	}
}

var clientConn net.Conn

func serve(conn net.Conn) {
	req, err := http.ReadRequest(bufio.NewReader(conn))
	if err != nil {
		log.Println("read req err", err)
		return
	}

	if req.URL.Path == protocol.RegisterPath {
		if req.Method != "CONNECT" {
			conn.Write([]byte(MustConnect))
			return
		}

		io.WriteString(conn, "HTTP/1.1 "+protocol.Connected+"\n\n")
		conn.SetDeadline(time.Time{})
		tunnelHandler.addTunnel("127.0.0.1:6000", NewTunnel(conn))
		// return
	}

	host := strings.ToLower(req.Host)
	tunnel, ok := tunnelHandler.getTunnel(host)
	if !ok {
		log.Println("no such tunnel", host)
		conn.Write([]byte(fmt.Sprintf(NotFound, len(host)+18, host)))
		return
	}

	// tunnel.clientConn.Write([]byte("start_proxy"))
	conn.SetDeadline(time.Time{})
	tunnel.join(conn)
}

type Tunnel struct {
	clientConn net.Conn
	start      time.Time
}

func NewTunnel(conn net.Conn) *Tunnel {
	return &Tunnel{
		clientConn: conn,
		start:      time.Now(),
	}
}

func (t *Tunnel) join(publicConn net.Conn) {
	log.Println("begin a new client join", publicConn.RemoteAddr().String())
	join.Join(publicConn, t.clientConn)
}

// func handleConnection(publicConn net.Conn) {
// 	listener, err := net.Listen("tcp4", ":0")
// 	if err != nil {
// 		log.Println("listen public err", err)
// 	}
// 	log.Println("new listener on ", listener.Addr())

// 	for {
// 		proxyConn, err := listener.Accept()
// 		if err != nil {
// 			log.Println("accept err: %s", err)
// 			continue
// 		}
// 		log.Println("got a new CONNNNN", proxyConn.LocalAddr().String())
// 		proxyConn.SetDeadline(time.Time{})

// 		go join.Join(publicConn, proxyConn)
// 	}
// 	log.Println("listener is ended !")
// }

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
