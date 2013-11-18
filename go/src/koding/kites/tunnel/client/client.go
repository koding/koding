package main

import (
	"fmt"
	"koding/kites/tunnel/protocol"
	"log"
	"net"
	"net/http"
	"net/http/httputil"
	"os"
)

var serverAddr = "127.0.0.1:7000"
var localAddr = "127.0.0.1:5000"
var registerPath = "_kdtunnel_"

func init() {
	log.SetOutput(os.Stdout)
	log.SetPrefix("tunnel-client ")
	log.SetFlags(log.Lmicroseconds)
}

type TunnelClient struct {
	remoteConn *httputil.ServerConn
	localConn  *httputil.ClientConn
	registered bool
}

func NewTunnelClient(localAddr string) *TunnelClient {
	remoteConn, err := net.Dial("tcp", serverAddr)
	if err != nil {
		log.Fatalln("dial remote err: %s", err)
	}

	localConn, err := net.Dial("tcp", localAddr)
	if err != nil {
		log.Fatalln("dial local err: %s", err)
	}

	tunnel := &TunnelClient{
		remoteConn: httputil.NewServerConn(remoteConn, nil),
		localConn:  httputil.NewClientConn(localConn, nil),
	}

	err = tunnel.Register()
	if err != nil {
		log.Fatalln(err)
	}

	fmt.Printf("Tunnel established from %s to %s\n", remoteConn.RemoteAddr(), localConn.RemoteAddr())
	return tunnel
}

func main() {
	tunnel := NewTunnelClient(localAddr)
	tunnel.Start()
}

func (t *TunnelClient) Start() {
	for {
		req, err := t.remoteConn.Read()
		if err != nil {
			fmt.Println("Server read", err)
			return
		}

		go t.handleReq(req)
	}
}

func (t *TunnelClient) handleReq(req *http.Request) {
	resp, err := t.localConn.Do(req)
	if err != nil {
		fmt.Println("could not do request")
	}

	t.remoteConn.Write(req, resp)
}

// Register registered the tunnel client to the TunnelServer via an CONNECT request.
// It returns an error if the connect request is not successful.
func (t *TunnelClient) Register() error {
	conn, buffer := t.remoteConn.Hijack()

	remoteAddr := fmt.Sprintf("http://%s%s", serverAddr, protocol.RegisterPath)
	req, err := http.NewRequest("CONNECT", remoteAddr, nil)
	if err != nil {
		return fmt.Errorf("CONNECT", err)
	}

	req.Header.Set("Username", "fatih")
	req.Write(conn)

	resp, err := http.ReadResponse(buffer, req)
	if err != nil {
		return fmt.Errorf("read response", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 && resp.Status != protocol.Connected {
		return fmt.Errorf("Non-200 response from proxy server: %s", resp.Status)
	}

	// hijack detaches the server, after doing raw tcp communication
	// attach it again to our tunnelclient
	t.remoteConn = httputil.NewServerConn(conn, nil)
	t.registered = true
	return nil
}
