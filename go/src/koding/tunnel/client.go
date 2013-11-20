package tunnel

import (
	"bufio"
	"fmt"
	"log"
	"net"
	"net/http"
	"net/http/httputil"
	"time"
)

type Client struct {
	remoteConn *reconnectConn
	localConn  *reconnectConn
}

// NewTunnelClient creates a new tunnel that is established between the
// serverAddr and localAddr.
func NewClient(serverAddr, localAddr string) *Client {
	remoteConn := dialTCP(serverAddr)
	remoteConn.SetKeepAlive(true)
	remoteConn.SetDeadline(time.Time{})

	localConn := dialTCP(localAddr)

	tunnel := &Client{
		remoteConn: newReconnectConn(remoteConn, time.Second*2),
		localConn:  newReconnectConn(localConn, time.Second*2),
	}

	err := tunnel.Register()
	if err != nil {
		log.Fatalln(err)
	}

	fmt.Printf("Tunnel established from %s to %s\n", remoteConn.RemoteAddr(), localConn.RemoteAddr())
	return tunnel
}

func dialTCP(addr string) *net.TCPConn {
	serverTcpAddr, err := net.ResolveTCPAddr("tcp4", addr)
	if err != nil {
		log.Fatalf("server addr %s\n", err)
	}

	conn, err := net.DialTCP("tcp", nil, serverTcpAddr)
	if err != nil {
		log.Fatalf("remote %s\n", err)
	}

	return conn
}

// Proxy is like Start() but it joins (proxies) the remote tcp connection with
// the local one, that means all de handling is done via those two connection.
func (c *Client) Proxy() {
	join(c.localConn, c.remoteConn)
}

// Start starts the tunnel between the remote and local server. It's a
// blocking function. Every requst is handled in a separete goroutine.
func (c *Client) Start() {
	serverconn := httputil.NewServerConn(c.remoteConn, nil)

	for {
		req, err := serverconn.Read()
		if err != nil {
			fmt.Println("Server read", err)
			return
		}

		go c.handleReq(serverconn, req)
	}
}

func (c *Client) handleReq(serverconn *httputil.ServerConn, req *http.Request) {
	clientconn := httputil.NewClientConn(c.localConn, nil)
	resp, err := clientconn.Do(req)
	if err != nil {
		fmt.Println("could not do request")
	}

	serverconn.Write(req, resp)
}

// Register registered the tunnel client to the TunnelServer via an CONNECT request.
// It returns an error if the connect request is not successful.
func (c *Client) Register() error {
	remoteAddr := fmt.Sprintf("http://%s%s", c.remoteConn.RemoteAddr(), RegisterPath)
	req, err := http.NewRequest("CONNECT", remoteAddr, nil)
	if err != nil {
		return fmt.Errorf("CONNECT", err)
	}

	req.Header.Set("Username", "fatih")
	req.Write(c.remoteConn)

	resp, err := http.ReadResponse(bufio.NewReader(c.remoteConn), req)
	if err != nil {
		return fmt.Errorf("read response", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 && resp.Status != Connected {
		return fmt.Errorf("Non-200 response from proxy server: %s", resp.Status)
	}

	return nil
}
