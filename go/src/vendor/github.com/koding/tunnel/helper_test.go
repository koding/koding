package tunnel_test

import (
	"bufio"
	"bytes"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"math/rand"
	"net"
	"net/http"
	"net/url"
	"os"
	"time"

	"github.com/koding/tunnel"
	"github.com/koding/tunnel/tunneltest"

	"github.com/gorilla/websocket"
)

func init() {
	rand.Seed(time.Now().UnixNano() + int64(os.Getpid()))
}

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
}

type EchoMessage struct {
	Value string `json:"value,omitempty"`
	Close bool   `json:"close,omitempty"`
}

var timeout = 10 * time.Second

var dialer = &websocket.Dialer{
	ReadBufferSize:   1024,
	WriteBufferSize:  1024,
	HandshakeTimeout: timeout,
	NetDial: func(_, addr string) (net.Conn, error) {
		return net.DialTimeout("tcp4", addr, timeout)
	},
}

func echoHTTP(tt *tunneltest.TunnelTest, echo string) (string, error) {
	req := tt.Request("http", url.Values{"echo": []string{echo}})
	if req == nil {
		return "", fmt.Errorf(`tunnel "http" does not exist`)
	}

	req.Close = rand.Int()%2 == 0

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	p, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return "", err
	}

	return string(bytes.TrimSpace(p)), nil
}

func echoTCP(tt *tunneltest.TunnelTest, echo string) (string, error) {
	return echoTCPIdent(tt, echo, "tcp")
}

func echoTCPIdent(tt *tunneltest.TunnelTest, echo, ident string) (string, error) {
	addr := tt.Addr(ident)
	if addr == nil {
		return "", fmt.Errorf("tunnel %q does not exist", ident)
	}
	s := addr.String()
	ip := tt.Tunnels[ident].IP
	if ip != nil {
		_, port, err := net.SplitHostPort(s)
		if err != nil {
			return "", err
		}
		s = net.JoinHostPort(ip.String(), port)
	}

	c, err := dialTCP(s)
	if err != nil {
		return "", err
	}

	c.out <- echo

	select {
	case reply := <-c.in:
		return reply, nil
	case <-time.After(tcpTimeout):
		return "", fmt.Errorf("timed out waiting for reply from %s (%s) after %v", s, addr, tcpTimeout)
	}
}

func websocketDial(tt *tunneltest.TunnelTest, ident string) (*websocket.Conn, error) {
	req := tt.Request(ident, nil)
	if req == nil {
		return nil, fmt.Errorf("no client found for ident %q", ident)
	}

	h := http.Header{"Host": {req.Host}}
	wsurl := fmt.Sprintf("ws://%s", tt.ServerAddr())

	conn, _, err := dialer.Dial(wsurl, h)
	return conn, err
}

func sleep() {
	time.Sleep(time.Duration(rand.Intn(2000)) * time.Millisecond)
}

func handlerEchoWS(sleepFn func()) func(w http.ResponseWriter, r *http.Request) error {
	return func(w http.ResponseWriter, r *http.Request) (e error) {
		conn, err := upgrader.Upgrade(w, r, nil)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return err
		}
		defer func() {
			err := conn.Close()
			if e == nil {
				e = err
			}
		}()

		if sleepFn != nil {
			sleepFn()
		}

		for {
			var msg EchoMessage
			err := conn.ReadJSON(&msg)
			if err != nil {
				return fmt.Errorf("ReadJSON error: %s", err)
			}

			if sleepFn != nil {
				sleepFn()
			}

			err = conn.WriteJSON(&msg)
			if err != nil {
				return fmt.Errorf("WriteJSON error: %s", err)
			}

			if msg.Close {
				return nil
			}
		}
	}
}

func handlerEchoHTTP(w http.ResponseWriter, r *http.Request) {
	io.WriteString(w, r.URL.Query().Get("echo"))
}

func handlerLatencyEchoHTTP(w http.ResponseWriter, r *http.Request) {
	sleep()
	handlerEchoHTTP(w, r)
}

func handlerEchoTCP(conn net.Conn) {
	io.Copy(conn, conn)
}

func handlerLatencyEchoTCP(conn net.Conn) {
	sleep()
	handlerEchoTCP(conn)
}

var tcpTimeout = 10 * time.Second

type tcpClient struct {
	conn    net.Conn
	scanner *bufio.Scanner
	in      chan string
	out     chan string
}

func (c *tcpClient) loop() {
	for out := range c.out {
		if _, err := fmt.Fprintln(c.conn, out); err != nil {
			log.Printf("[tunnelclient] error writing %q to %q: %s", out, c.conn.RemoteAddr(), err)
			return
		}

		if !c.scanner.Scan() {
			log.Printf("[tunnelclient] error reading from %q: %v", c.conn.RemoteAddr(), c.scanner.Err())
			return
		}

		c.in <- c.scanner.Text()
	}
}

func (c *tcpClient) Close() error {
	close(c.out)
	return c.conn.Close()
}

func dialTCP(addr string) (*tcpClient, error) {
	conn, err := net.DialTimeout("tcp", addr, tcpTimeout)
	if err != nil {
		return nil, err
	}

	c := &tcpClient{
		conn:    conn,
		scanner: bufio.NewScanner(conn),
		in:      make(chan string, 1),
		out:     make(chan string, 1),
	}

	go c.loop()

	return c, nil
}

func singleHTTP(handler interface{}) map[string]*tunneltest.Tunnel {
	return singleRecHTTP(handler, nil)
}

func singleRecHTTP(handler interface{}, stateChanges chan<- *tunnel.ClientStateChange) map[string]*tunneltest.Tunnel {
	return map[string]*tunneltest.Tunnel{
		"http": {
			Type:         tunneltest.TypeHTTP,
			LocalAddr:    "127.0.0.1:0",
			Handler:      handler,
			StateChanges: stateChanges,
		},
	}
}

func singleTCP(handler interface{}) map[string]*tunneltest.Tunnel {
	return singleRecTCP(handler, nil)
}

func singleRecTCP(handler interface{}, stateChanges chan<- *tunnel.ClientStateChange) map[string]*tunneltest.Tunnel {
	return map[string]*tunneltest.Tunnel{
		"http": {
			Type:         tunneltest.TypeHTTP,
			LocalAddr:    "127.0.0.1:0",
			Handler:      handlerEchoHTTP,
			StateChanges: stateChanges,
		},
		"tcp": {
			Type:        tunneltest.TypeTCP,
			ClientIdent: "http",
			LocalAddr:   "127.0.0.1:0",
			RemoteAddr:  "127.0.0.1:0",
			Handler:     handler,
		},
	}
}
