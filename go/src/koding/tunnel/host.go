package tunnel

import (
	"sync"
)

type virtualHost struct {
	username string
}

// virtualHosts is used for mapping host to users example: host
// "fs-1-fatih.kd.io" belongs to user "arslan"
type virtualHosts struct {
	mapping map[string]*virtualHost
	sync.Mutex
}

func newVirtualHosts() *virtualHosts {
	return &virtualHosts{
		mapping: make(map[string]*virtualHost),
	}
}

func (v *virtualHosts) addHost(host, username string) {
	v.Lock()
	defer v.Unlock()

	v.mapping[host] = &virtualHost{username: username}
}

func (v *virtualHosts) deleteHost(host string) {
	v.Lock()
	defer v.Unlock()

	delete(v.mapping, host)
}

// getUsername returns the username associated with the given host
func (v *virtualHosts) getUsername(host string) (string, bool) {
	v.Lock()
	defer v.Unlock()

	ht, ok := v.mapping[host]
	if !ok {
		return "", false
	}

	return ht.username, true
}

// getHost returns the host associated with the given username
func (v *virtualHosts) getHost(username string) (string, bool) {
	v.Lock()
	defer v.Unlock()

	for hostname, hst := range v.mapping {
		if hst.username == username {
			return hostname, true
		}
	}

	return "", false
}
