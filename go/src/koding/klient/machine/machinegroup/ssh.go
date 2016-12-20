package machinegroup

import (
	"errors"
	"net"
	"strconv"

	"koding/kites/tunnelproxy/discover"
	"koding/klient/machine"
)

// SSHInfoRequest defines machine group ssh info request.
type SSHRequest struct {
	// ID is a unique identifier for the remote machine.
	ID machine.ID `json:"id"`

	// Username defines the remote machine user name. This field is optional, if
	// not set, the current remote user will be used instead.
	Username string `json:"username"`

	// PublicKey contains local machine public key content which is meant to be
	// added to remote machine authorized_keys file. This field is optional, if
	// not set, no keys will be added.
	PublicKey string `json:"public_key"`
}

// SSHInfoResponse defines machine group ssh info response.
type SSHResponse struct {
	// Username defines the remote machine user name.
	Username string `json:"username"`

	// Host is the remote machine host used for SSH connections.
	Host string `json:"host"`

	// Port defines remote machine SSH listening port.
	Port int `json:"port"`
}

// Create updates internal state of machine group. It gets the current
// information about user machines so it can add new ones to group.
func (g *Group) SSH(req *SSHRequest) (*SSHResponse, error) {
	if req == nil {
		return nil, errors.New("invalid nil request")
	}

	c, err := g.client.Client(req.ID)
	if err != nil {
		return nil, err
	}

	// Use provided username or ask remote machine to return it.
	username := req.Username
	if username == "" {
		if username, err = c.CurrentUser(); err != nil {
			return nil, err
		}
	}

	// Add pubic key to remote machine authorized keys.
	if req.PublicKey != "" {
		if err := c.SSHAddKeys(username, req.PublicKey); err != nil {
			return nil, err
		}
	}

	// Check for tunneled connections.
	addr, err := g.address.Latest(req.ID, "tunnel")
	if err != nil {
		// There are no tunnel addresses. Get latest IP.
		if addr, err = g.address.Latest(req.ID, "ip"); err != nil {
			return nil, err
		}

		return &SSHResponse{
			Username: username,
			Host:     addr.Value,
		}, nil
	}

	// Discover tunnel SSH address.
	endpoints, err := g.discover.Discover(addr.Value, "ssh")
	if err != nil {
		return &SSHResponse{
			Username: username,
			Host:     addr.Value,
		}, nil
	}

	tuneladdr := endpoints[0].Addr
	// We prefer local routes to use first, if there's none, we use first
	// discovered route.
	if e := endpoints.Filter(discover.ByLocal(true)); len(e) != 0 {
		// All local routes will do, typically there's only one,
		// we use the first one and ignore the rest.
		tuneladdr = e[0].Addr
	}

	host, port, err := net.SplitHostPort(tuneladdr)
	if err != nil {
		host, port = tuneladdr, "0"
	}

	n, err := strconv.Atoi(port)
	if err != nil {
		return nil, err
	}

	return &SSHResponse{
		Username: username,
		Host:     host,
		Port:     n,
	}, nil
}
