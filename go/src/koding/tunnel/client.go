package tunnel

import (
	"bufio"
	"fmt"
	"log"
	"net/http"
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

	fmt.Printf("Tunnel established from %s to %s\n",
		remoteConn.RemoteAddr(), localConn.RemoteAddr())

	return tunnel
}

// Proxy is like Start() but it joins (proxies) the remote tcp connection with
// the local one, that means all de handling is done via those two connection.
func (c *Client) Proxy() {
	err := <-join(c.localConn, c.remoteConn)
	log.Println(err)
}

// Start starts the tunnel between the remote and local server. It's a
// blocking function. Every requst is handled in a separete goroutine.
func (c *Client) Start() {
	for {
		req, err := http.ReadRequest(bufio.NewReader(c.remoteConn))
		if err != nil {
			fmt.Println("Server read", err)
			return
		}

		go c.handleReq(req)
	}
}

func (c *Client) handleReq(req *http.Request) {
	err := req.Write(c.localConn)
	if err != nil {
		log.Println("write clientConn ", err)
		return
	}

	resp, err := http.ReadResponse(bufio.NewReader(c.localConn), req)
	if err != nil {
		fmt.Println("read response")
		return
	}

	err = resp.Write(c.remoteConn)
	if err != nil {
		fmt.Println("resp.write")
		return
	}
}

// Register registered the tunnel client to the TunnelServer via an CONNECT
// request. It returns an error if the connect request is not successful.
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
