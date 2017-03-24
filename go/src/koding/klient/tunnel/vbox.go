package tunnel

import (
	"bytes"
	"errors"
	"fmt"
	"net"
	"net/url"
	"strconv"
	"strings"
	"time"

	"koding/kites/tunnelproxy"
	"koding/klient/tunnel/tlsproxy/pem"
	"koding/klient/vagrant"
	"koding/tools/util"

	"github.com/koding/kite"
	"github.com/koding/tunnel"
)

// Port describes port numbers of a tunnel connection.
type Port struct {
	// Local is a port number of the local server (private end of the tunnel).
	// It is non-0 for tunnel clients which run directly on a host network
	// (no VirtualBox, Docker etc. NAT).
	//
	// It may be 0 when tunnel is created for a Vagrant box, which does
	// not have its port forwarded to the host - in this case the NAT
	// field is the local server port inside the vm.
	//
	// This end of a tunnel is accessible under 127.0.0.1:<Local>.
	Local int `json:"local,omitempty"`

	// NAT is a port number of the local server which runs inside
	// a Vagrant box.
	//
	// It is 0 when tunnel client runs directly on the host network.
	NAT int `json:"nat,omitempty"`

	// Remote is a port number of public end of the tunnel. It is
	// always non-0.
	//
	// This end of a tunnel is accessuble under <VirtualHost>:<Remote>.
	Remote int `json:"remote"`
}

type InfoResponse struct {
	Name        string `json:"name"`      // tunnel name, e.g.62ee1f899a4e
	VirtualHost string `json:"vhost"`     // tunenl vhost, e.g. 62ee1f899a4e.rafal.koding.me
	PublicIP    string `json:"publicIp"`  // public IP of the tunnel client
	State       string `json:"state"`     // state of the tunnel
	IsVagrant   bool   `json:"isVagrant"` // whether we NATed behind Vagrant network

	Ports map[string]*Port `json:"ports,omitempty"`
}

const (
	StateNotStarted   = "NotStarted"
	StateStarted      = "Started"
	StateConnecting   = "Connecting"
	StateConnected    = "Connected"
	StateDisconnected = "Disconnected"
	StateClosed       = "Closed"
)

var stateNames = map[tunnel.ClientState]string{
	tunnel.ClientUnknown:      StateNotStarted,
	tunnel.ClientStarted:      StateStarted,
	tunnel.ClientConnecting:   StateConnected,
	tunnel.ClientConnected:    StateConnected,
	tunnel.ClientDisconnected: StateDisconnected,
	tunnel.ClientClosed:       StateClosed,
}

func (t *Tunnel) Info(r *kite.Request) (interface{}, error) {
	var info InfoResponse

	t.mu.Lock()
	defer t.mu.Unlock()

	info.State = stateNames[t.state]

	// If tunnel is not connected, then no tunnels are available.
	if t.state != tunnel.ClientConnected {
		return info, nil
	}

	info.Name = t.opts.TunnelName
	info.VirtualHost = t.opts.VirtualHost
	info.PublicIP = t.opts.PublicIP.String()
	info.IsVagrant = t.isVagrant

	// Build tunnel information.
	info.Ports = map[string]*Port{
		"kite":  {Remote: 80},  // HTTP kite server
		"kites": {Remote: 443}, // HTTPS kite server (actually TLS reverse proxy)
	}

	t.setLocalOrNAT(&info, "kite", t.opts.Kite.Config.Port)
	t.setLocalOrNAT(&info, "kites", 56790)

	// Update kite tunnel (public endpoint) remote port, it may be
	// needed when run against custom tunnelserver, which listens
	// on different port than default 80.
	if _, port, err := parseHostPort(info.VirtualHost); err == nil && port != 0 {
		info.Ports["kite"].Remote = port
	}

	return info, nil
}

func (t *Tunnel) setLocalOrNAT(info *InfoResponse, name string, localOrNAT int) {
	if info.IsVagrant {
		info.Ports[name].NAT = localOrNAT

		// Find forwarded port
		for _, p := range t.ports {
			if p.GuestPort == localOrNAT {
				info.Ports[name].Local = p.HostPort
				break
			}
		}
	} else {
		info.Ports[name].Local = localOrNAT
	}
}

type PrintablePorts []*vagrant.ForwardedPort

func (p PrintablePorts) String() string {
	if len(p) == 0 {
		return "[]"
	}

	var buf bytes.Buffer

	fmt.Fprintf(&buf, "[%+v", p[0])

	for _, p := range p[1:] {
		fmt.Fprintf(&buf, ",%+v", p)
	}

	buf.WriteRune(']')

	return buf.String()
}

func (t *Tunnel) kiteServices(kiteAddr, kitesAddr string) map[string]*tunnelproxy.Tunnel {
	return map[string]*tunnelproxy.Tunnel{
		"kite": {
			Name:      "kite",
			PublicIP:  t.opts.PublicIP.String(),
			LocalAddr: kiteAddr,
		},
		"kites": {
			Name:      "kites",
			PublicIP:  t.opts.PublicIP.String(),
			LocalAddr: kitesAddr,
		},
	}
}

func (t *Tunnel) hostPort(guestPort int) int {
	for _, p := range t.ports {
		if p.GuestPort == guestPort {
			return p.HostPort
		}
	}

	return 0
}

// buildServices gives route information of tunnelclient kite services.
//
// If the kite server runs inside a VirtualBox machine, localRoute
// returns a route to the forwarded port on the host network.
func (t *Tunnel) buildServices() map[string]*tunnelproxy.Tunnel {
	ok, err := vagrant.IsVagrant()
	if err != nil {
		t.opts.Log.Error("failure checking local route: %s", err)

		return t.kiteServices("", "") // no local routing
	}

	if !ok {
		return t.kiteServices(t.opts.LocalAddr, net.JoinHostPort(pem.Hostname, "56790")) // local routing without forwarded ports
	}

	t.isVagrant = true

	_, kitePort, err := parseHostPort(t.opts.LocalAddr)
	if err != nil {
		t.opts.Log.Error("invalid local address: %s", err)

		return nil
	}

	ports, err := t.forwardedPorts()
	if err != nil {
		t.opts.Log.Error("failure checking local route: %s", err)

		return nil
	}

	t.opts.Log.Debug("forwarded ports: %+v", PrintablePorts(ports))
	t.ports = ports

	kiteHostPort := t.hostPort(kitePort)
	kitesHostPort := t.hostPort(56790)

	if kiteHostPort == 0 {
		t.opts.Log.Error("unable to find forwarded host port for %d: %+v", kitePort, t.ports)

		return t.kiteServices("", "") // no local routing
	}

	if kitesHostPort == 0 {
		t.opts.Log.Error("unable to find forwarded host port for 56790: %+v", t.ports)

		return t.kiteServices("", "") // no local routing
	}

	kiteAddr := net.JoinHostPort("127.0.0.1", strconv.Itoa(kiteHostPort))
	kitesAddr := net.JoinHostPort(pem.Hostname, strconv.Itoa(kitesHostPort))

	return t.kiteServices(kiteAddr, kitesAddr) // local routing
}

func (t *Tunnel) gateways() (map[string]string, error) {
	routes, err := util.ParseRoutes()
	if err != nil {
		return nil, err
	}

	gateways := make(map[string]string)

	for _, r := range routes {
		if !begins(r.Iface, "eth") {
			continue
		}

		if r.Gateway == nil {
			continue
		}

		gateways[r.Iface] = r.Gateway.String()
	}

	if len(gateways) == 0 {
		return nil, errors.New("no interfaces found")
	}

	return gateways, nil
}

func (t *Tunnel) gateway() (string, error) {
	gateways, err := t.gateways()
	if err != nil {
		return "", fmt.Errorf("failure reading routing table: %s", err)
	}

	addr, ok := gateways["eth0"]
	if !ok {
		for _, a := range gateways {
			addr = a // pick first non-eth0 interface (eth1?)
			break
		}
	}

	return addr, nil
}

func (t *Tunnel) dialHostKite(addr string) (*kite.Client, error) {
	hostKiteURL := &url.URL{
		Scheme: "http",
		Host:   addr,
		Path:   "/kite",
	}

	client := t.opts.Kite.NewClient(hostKiteURL.String())
	client.Auth = &kite.Auth{
		Type: "kiteKey",
		Key:  t.opts.Kite.Config.KiteKey,
	}
	client.Reconnect = true

	if err := client.DialTimeout(7 * time.Second); err != nil {
		return nil, err
	}

	return client, nil
}

func (t *Tunnel) forwardedPorts() ([]*vagrant.ForwardedPort, error) {
	if t.opts.TunnelName == "" {
		return nil, errors.New("failue checking local route: missing tunnel name")
	}

	// If we're a kite inside vagrant, we call host kite asking
	// about forwarded ports. TunnelName is assigned by the host
	// kite and is equal to jMachines.Uid for the given vagrant
	// vm. The VirtualBox machine name is always prefixed by
	// the jMachines.Uid.
	addr, err := t.gateway()
	if err != nil {
		return nil, err
	}

	// NOTE(rjeczalik): we assume host kite is on port 56789 (all installer
	// scripts use it as default one) and the host kite listens on all
	// interfaces.
	addr = net.JoinHostPort(addr, "56789")

	client, err := t.dialHostKite(addr)
	if err != nil {
		return nil, fmt.Errorf("failure dialing host kite %q: %s", addr, err)
	}
	defer client.Close()

	req := &vagrant.ForwardedPortsRequest{
		Name: t.opts.TunnelName,
	}

	resp, err := client.TellWithTimeout("vagrant.listForwardedPorts", 15*time.Second, req)
	if err != nil {
		return nil, fmt.Errorf("failure calling listForwardedPorts: %s", err)
	}

	var ports []*vagrant.ForwardedPort
	if err := resp.Unmarshal(&ports); err != nil {
		return nil, fmt.Errorf("failure reading response: %s", err)
	}

	if len(ports) == 0 {
		return nil, errors.New("no forwarded ports found")
	}

	return ports, nil
}

func parseHostPort(addr string) (string, int, error) {
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

func begins(s string, substrs ...string) bool {
	if s == "" {
		return true
	}

	for _, substr := range substrs {
		if strings.HasPrefix(s, substr) {
			return true
		}
	}

	return false
}
