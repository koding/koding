package tunnelproxy

import (
	"errors"
	"fmt"
	"net"
	"strconv"
	"sync"

	"github.com/hashicorp/go-multierror"
	"github.com/koding/ec2dynamicdata"
)

// Tunnel
type Tunnel struct {
	Name        string `json:"name"`
	Port        int    `json:"port"`
	VirtualHost string `json:"virtualHost"`
	Error       string `json:"error,omitempty"`
}

func (t *Tunnel) Err() error {
	if t.Error != "" {
		return errors.New(t.Error)
	}
	return nil
}

type TunnelsByName []*Tunnel

func (t TunnelsByName) Len() int           { return len(t) }
func (t TunnelsByName) Less(i, j int) bool { return t[i].Name < t[j].Name }
func (t TunnelsByName) Swap(i, j int)      { t[i], t[j] = t[j], t[i] }

var errAlreadyExists = errors.New("already exists")

// Tunnels
type Tunnels struct {
	m map[string]map[string]*Tunnel
}

func newTunnels() *Tunnels {
	return &Tunnels{
		m: make(map[string]map[string]*Tunnel),
	}
}

func (t *Tunnels) addClient(ident, name, vhost string) {
	client, ok := t.m[ident]

	if !ok {
		client = make(map[string]*Tunnel)
		t.m[ident] = client
	}

	client[""] = &Tunnel{
		Name:        name,
		VirtualHost: vhost,
	}
}

func (t *Tunnels) delClient(ident string) {
	delete(t.m, ident)
}

func (t *Tunnels) addClientService(ident string, tun *Tunnel) error {
	client, ok := t.m[ident]
	if !ok {
		return fmt.Errorf("client with ident %q does not exist", ident)
	}

	if _, ok := client[tun.Name]; ok {
		return errAlreadyExists
	}

	client[tun.Name] = tun

	return nil
}

func (t *Tunnels) delClientService(ident, name string) {
	delete(t.m[ident], name)
}

func (t *Tunnels) tunnel(ident, name string) *Tunnel {
	return t.m[ident][name]
}

func publicIP() (string, error) {
	return ec2dynamicdata.GetMetadata(ec2dynamicdata.PublicIPv4)
}

// customPort adds a port part to the given address. If port is a zero-value,
// or the addr parameter already has a port set - this function is a nop.
func customPort(addr string, port int, ignore ...int) string {
	if addr == "" {
		return ""
	}

	if port == 0 {
		return addr
	}

	for _, n := range ignore {
		if port == n {
			return addr
		}
	}

	_, sport, err := net.SplitHostPort(addr)
	if err != nil || sport == "" || sport == "0" {
		return net.JoinHostPort(addr, strconv.Itoa(port))
	}

	return addr
}

func port(addr string) int {
	_, sport, err := net.SplitHostPort(addr)
	if err == nil {
		n, err := strconv.ParseUint(sport, 10, 16)
		if err == nil {
			return int(n)
		}
	}

	return 0
}

type callbacks struct {
	mu sync.Mutex
	m  map[string][]func() error
}

func newCallbacks() *callbacks {
	return &callbacks{
		m: make(map[string][]func() error),
	}
}

func (c *callbacks) add(ident string, fn func() error) {
	c.mu.Lock()
	c.m[ident] = append(c.m[ident], fn)
	c.mu.Unlock()
}

func (c *callbacks) call(ident string) (err error) {
	c.mu.Lock()
	fns, ok := c.m[ident]
	delete(c.m, ident)
	c.mu.Unlock()

	if !ok {
		return nil
	}

	for i := range fns {
		// Start executing from callbacks from the newest to the oldest (like defer).
		fn := fns[len(fns)-i-1]

		// Ensure panic in a callback does not break executing other callbacks.
		func(fn func() error) {
			defer func() {
				if v := recover(); v != nil {
					e, ok := v.(error)
					if !ok {
						e = fmt.Errorf("%v", v)
					}
					err = multierror.Append(err, e)
				}
			}()

			if e := fn(); e != nil {
				err = multierror.Append(err, e)
			}
		}(fn)
	}

	return err
}
