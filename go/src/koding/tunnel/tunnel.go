package tunnel

import (
	"net"
	"sync"
	"time"
)

type Tunnel struct {
	conn  net.Conn
	start time.Time
}

func NewTunnel(conn net.Conn) *Tunnel {
	return &Tunnel{
		conn:  conn,
		start: time.Now(),
	}
}

type Tunnels struct {
	sync.Mutex
	tunnels map[string]*Tunnel
}

func NewTunnels() *Tunnels {
	return &Tunnels{
		tunnels: make(map[string]*Tunnel),
	}
}

func (t *Tunnels) getTunnel(protocol string) (*Tunnel, bool) {
	t.Lock()
	defer t.Unlock()

	tunnel, ok := t.tunnels[protocol]
	return tunnel, ok
}

func (t *Tunnels) addTunnel(protocol string, tunnel *Tunnel) {
	t.Lock()
	defer t.Unlock()

	t.tunnels[protocol] = tunnel
}
