package tunnel

import (
	"sync"
)

type Host struct {
	username string
}

// Hosts is used for mapping host to users example: host
// "fs-1-fatih.kd.io" belongs to user "arslan"
type Hosts struct {
	mapping map[string]*Host
	sync.Mutex
}

func newHosts() *Hosts {
	return &Hosts{
		mapping: make(map[string]*Host),
	}
}

func (h *Hosts) addHost(host, username string) {
	h.Lock()
	defer h.Unlock()

	h.mapping[host] = &Host{username: username}
}

func (h *Hosts) deleteHost(host string) {
	h.Lock()
	defer h.Unlock()

	delete(h.mapping, host)
}

// getUsername returns the username associated with the given host
func (h *Hosts) getUsername(host string) (string, bool) {
	h.Lock()
	defer h.Unlock()

	ht, ok := h.mapping[host]
	if !ok {
		return "", false
	}

	return ht.username, true
}

// getHost returns the host associated with the given username
func (h *Hosts) getHost(username string) (string, bool) {
	h.Lock()
	defer h.Unlock()

	for hostname, hst := range h.mapping {
		if hst.username == username {
			return hostname, true
		}
	}

	return "", false
}
