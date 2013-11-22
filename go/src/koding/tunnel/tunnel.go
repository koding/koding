package tunnel

import (
	"net"
	"sync"
	"time"
)

type tunnel struct {
	conn  net.Conn
	start time.Time
}

func newTunnel(conn net.Conn) *tunnel {
	return &tunnel{
		conn:  conn,
		start: time.Now(),
	}
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
