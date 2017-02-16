package tunnelproxy

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"net"
	"net/http"
	"strconv"
	"sync"

	multierror "github.com/hashicorp/go-multierror"
	"github.com/koding/ec2dynamicdata"
)

// TODO(rjeczalik): forward ports on host klient for TCP services

type Service struct {
	Name          string `json:"name"`
	LocalAddr     string `json:"localAddr"`
	RemoteAddr    string `json:"remoteAddr"`              // tunnel.Port
	ForwardedPort int    `json:"forwardedPort,omitempty"` // tunnel.LocalAddr
}

type Services map[string]*Service

func (s Services) String() string {
	p, err := json.Marshal(s)
	if err != nil {
		return fmt.Sprintf("%+q", s)
	}

	return string(p)
}

type Endpoint struct {
	Addr     string `json:"addr"`
	Protocol string `json:"protocol"`
	Local    bool   `json:"local"`
}

type Tunnel struct {
	Name        string `json:"name,omitempty"`
	Port        int    `json:"port,omitempty"` // tries to use fixed port number or restore
	VirtualHost string `json:"virtualHost,omitempty"`
	Error       string `json:"error,omitempty"`
	Restore     bool   `json:"restore,omitempty"`

	// Local routing.
	PublicIP  string `json:"publicIP,omitempty"`
	LocalAddr string `json:"localAddr,omitempty"` // either local port or forwarded one (related to package TODO)
}

func (t *Tunnel) String() string {
	p, err := json.Marshal(t)
	if err != nil {
		return fmt.Sprintf("%+v", t)
	}

	return string(p)
}

func (t *Tunnel) Err() error {
	if t.Error != "" {
		return errors.New(t.Error)
	}
	return nil
}

func (t *Tunnel) remoteEndpoint(proto string) *Endpoint {
	e := &Endpoint{
		Addr:     t.VirtualHost,
		Protocol: proto,
	}

	if t.Port != 0 {
		e.Addr = net.JoinHostPort(t.VirtualHost, strconv.Itoa(t.Port))
	}

	return e
}

func (t *Tunnel) localEndpoint(proto string) *Endpoint {
	return &Endpoint{
		Addr:     t.LocalAddr,
		Protocol: proto,
		Local:    true,
	}
}

type TunnelsByName []*Tunnel

func (t TunnelsByName) Len() int           { return len(t) }
func (t TunnelsByName) Less(i, j int) bool { return t[i].Name < t[j].Name }
func (t TunnelsByName) Swap(i, j int)      { t[i], t[j] = t[j], t[i] }

func (t TunnelsByName) String() string {
	if len(t) == 0 {
		return "[]"
	}

	var buf bytes.Buffer

	fmt.Fprintf(&buf, "[%s", t[0])

	for _, t := range t {
		fmt.Fprintf(&buf, ",%s", t)
	}

	buf.WriteRune(']')

	return buf.String()
}

var errAlreadyExists = errors.New("already exists")

// Tunnels
type Tunnels struct {
	m map[string]map[string]*Tunnel // maps ident to service name to service desc
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

func privateIP() (string, error) {
	return ec2dynamicdata.GetMetadata(ec2dynamicdata.LocalIPv4)
}

func instanceID() (string, error) {
	return ec2dynamicdata.GetMetadata(ec2dynamicdata.InstanceId)
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

func host(addr string) string {
	host, _, err := net.SplitHostPort(addr)
	if err == nil {
		return host
	}

	return addr
}

func parseIP(ip string) string {
	if ip == "" {
		return ""
	}

	host, _, err := net.SplitHostPort(ip)
	if err == nil {
		ip = host
	}

	if net.ParseIP(ip) != nil {
		return ip
	}

	return ""
}

func splitHostPort(addr string) (string, int, error) {
	host, port, err := net.SplitHostPort(addr)
	if err != nil {
		return "", 0, err
	}

	n, err := strconv.ParseUint(port, 10, 16)
	if err != nil {
		return "", 0, err
	}

	return host, int(n), nil
}

func extractIPs(r *http.Request) map[string]struct{} {
	ips := map[string]struct{}{
		parseIP(r.RemoteAddr):              {},
		parseIP(r.Header.Get("X-Real-IP")): {},
	}

	for _, ip := range r.Header["X-Forwarded-For"] {
		ips[parseIP(ip)] = struct{}{}
	}

	delete(ips, "")

	return ips
}

type callbacks struct {
	mu sync.Mutex
	m  map[string][]func() error
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
