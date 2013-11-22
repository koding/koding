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

func (t *tunnels) getTunnel(protocol string) (*tunnel, bool) {
	t.Lock()
	defer t.Unlock()

	tunnel, ok := t.tunnels[protocol]
	return tunnel, ok
}

func (t *tunnels) addTunnel(protocol string, tunnel *tunnel) {
	t.Lock()
	defer t.Unlock()

	t.tunnels[protocol] = tunnel
}
