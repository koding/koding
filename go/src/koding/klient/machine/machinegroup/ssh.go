package machinegroup

import (
	"errors"
	"fmt"
	"net"
	"strconv"
	"sync"
	"time"

	"koding/kites/config"
	"koding/kites/tunnelproxy/discover"
	"koding/klient/machine"
	"koding/klient/machine/client"
	msync "koding/klient/machine/mount/sync"
	"koding/klientctl/ssh"
)

// SSHRequest defines machine group ssh info request.
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

// SSHResponse defines machine group ssh info response.
type SSHResponse struct {
	// Username defines the remote machine user name.
	Username string `json:"username"`

	// Host is the remote machine host used for SSH connections.
	Host string `json:"host"`

	// Port defines remote machine SSH listening port.
	Port int `json:"port"`
}

// SSH prepares remote machine for SSH connection and returns necessary data
// to connect it via SSH protocol.
func (g *Group) SSH(req *SSHRequest) (*SSHResponse, error) {
	if req == nil {
		return nil, errors.New("invalid nil request")
	}

	username, err := g.ensureSSHPubKey(req.ID, req.Username, req.PublicKey)
	if err != nil {
		return nil, err
	}

	host, port, err := g.dynamicSSH(req.ID)()
	if err != nil {
		return nil, err
	}

	return &SSHResponse{
		Username: username,
		Host:     host,
		Port:     port,
	}, nil
}

// remoteUser stores remote user name or error if username is not available.
type remoteUser struct {
	Username string
	Err      error
}

// sshKey asynchronously adds local machine public key to remote machine.
func (g *Group) sshKey(id machine.ID, timeout time.Duration) <-chan remoteUser {
	internalC, ruC := make(chan remoteUser, 1), make(chan remoteUser, 1)
	go func() {
		pubKey, err := userSSHPublicKey()
		if err != nil {
			internalC <- remoteUser{
				Username: "",
				Err:      err,
			}
			return
		}
		username, err := g.ensureSSHPubKey(id, "", pubKey)
		internalC <- remoteUser{
			Username: username,
			Err:      err,
		}
	}()

	go func() {
		select {
		case <-time.After(timeout):
			ruC <- remoteUser{
				Username: "",
				Err:      fmt.Errorf("cannot add SSH public key to remote machine: connection timeout"),
			}
		case ru := <-internalC:
			ruC <- ru
		}
	}()

	return ruC
}

func (g *Group) ensureSSHPubKey(id machine.ID, username, pubKey string) (string, error) {
	// How long to wait for a valid client.
	const timeout = 30 * time.Second

	var err error

	dynClient := func() (client.Client, error) { return g.client.Client(id) }
	// Use provided username or ask remote machine to return it.
	c := client.NewSupervised(dynClient, timeout)
	if username == "" {
		if username, err = c.CurrentUser(); err != nil {
			return "", err
		}
	}

	// Add pubic key to remote machine authorized keys.
	if pubKey != "" {
		if err := c.SSHAddKeys(username, pubKey); err != nil {
			return "", err
		}
	}

	return username, nil
}

func (g *Group) dynamicSSH(id machine.ID) msync.DynamicSSHFunc {
	var (
		mtx  sync.Mutex
		addr machine.Addr
		host string
		port int
	)

	return func() (string, int, error) {
		// Check for tunneled connections.
		a, err := g.address.Latest(id, "tunnel")
		if err != nil {
			// There are no tunnel addresses. Get latest IP.
			if a, err = g.address.Latest(id, "ip"); err != nil {
				return "", 0, err
			}

			return a.Value, 0, nil
		}

		// Use a pseudo-cache in order to not call discover each time.
		mtx.Lock()
		if addr == a {
			mtx.Unlock()
			return host, port, nil
		}
		mtx.Unlock()

		// Discover tunnel SSH address.
		endpoints, err := g.discover.Discover(a.Value, "ssh")
		if err != nil {
			return "", 0, err
		}

		tunnelAddr := endpoints[0].Addr
		// We prefer local routes to use first, if there's none, we use first
		// discovered route.
		if e := endpoints.Filter(discover.ByLocal(true)); len(e) != 0 {
			// All local routes will do, typically there's only one,
			// we use the first one and ignore the rest.
			tunnelAddr = e[0].Addr
		}

		h, p, err := net.SplitHostPort(tunnelAddr)
		if err != nil {
			h, p = tunnelAddr, "0"
		}

		n, err := strconv.Atoi(p)
		if err != nil {
			return "", 0, err
		}

		// Cache results.
		mtx.Lock()
		addr, host, port = a, h, n
		mtx.Unlock()

		return host, port, nil
	}
}

// userSSHPublicKey gets the user's public SSH key content.
func userSSHPublicKey() (string, error) {
	path, err := ssh.GetKeyPath(config.CurrentUser.User)
	if err != nil {
		return "", err
	}

	pubKeyPath, privKeyPath, err := ssh.KeyPaths(path)
	if err != nil {
		return "", err
	}

	pubKey, err := ssh.PublicKey(pubKeyPath)
	if err != nil && err != ssh.ErrPublicKeyNotFound {
		return "", err
	}

	// Generate new key pair if it does not exist.
	if err == ssh.ErrPublicKeyNotFound {
		if pubKey, _, err = ssh.GenerateSaved(pubKeyPath, privKeyPath); err != nil {
			return "", err
		}
	}

	return pubKey, nil
}
