package tunnel

import (
	"bufio"
	"fmt"
	"koding/tunnel/conn"
	"log"
	"net"
	"net/http"
	"sync"
	"time"
)

type tunnel struct {
	// underlying tcp connection
	*conn.Conn

	// start time of the tunnel connection
	start time.Time
}

func newTunnel(nc net.Conn) *tunnel {
	t := &tunnel{
		start: time.Now(),
	}

	t.Conn = conn.New(nc, false)
	return t
}

func newTunnelDial(addr string, serverMsg *ServerMsg) *tunnel {
	t := &tunnel{}
	t.Conn = conn.Dial(addr, false)

	err := t.connect(serverMsg)
	if err != nil {
		log.Fatalln("newTunnelConn", err)
	}

	return t
}

func (t *tunnel) connect(serverMsg *ServerMsg) error {
	remoteAddr := fmt.Sprintf("http://%s%s", t.RemoteAddr(), TunnelPath)
	req, err := http.NewRequest("CONNECT", remoteAddr, nil)
	if err != nil {
		return fmt.Errorf("CONNECT", err)
	}

	req.Header.Set("protocol", serverMsg.Protocol)
	req.Header.Set("tunnelID", serverMsg.TunnelID)
	req.Header.Set("username", serverMsg.Username)
	req.Write(t)

	resp, err := http.ReadResponse(bufio.NewReader(t), req)
	if err != nil {
		return fmt.Errorf("read response", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 && resp.Status != Connected {
		return fmt.Errorf("Non-200 response from proxy server: %s", resp.Status)
	}

	return nil
}

type tunnels struct {
	sync.Mutex
	tunnels map[string]*tunnel
}

func newTunnels() *tunnels {
	return &tunnels{
		tunnels: make(map[string]*tunnel),
	}
}

func (t *tunnels) getTunnel(host string) (*tunnel, bool) {
	t.Lock()
	defer t.Unlock()

	tunnel, ok := t.tunnels[host]
	return tunnel, ok
}

func (t *tunnels) addTunnel(host string, tunnel *tunnel) {
	t.Lock()
	defer t.Unlock()

	t.tunnels[host] = tunnel
}

func (t *tunnels) deleteTunnel(host string) {
	t.Lock()
	defer t.Unlock()

	delete(t.tunnels, host)
}
