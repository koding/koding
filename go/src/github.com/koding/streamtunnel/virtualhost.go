package streamtunnel

import (
	"sync"
)

type virtualHost struct {
	identifier string
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

func (v *virtualHosts) addHost(host, identifier string) {
	v.Lock()
	v.mapping[host] = &virtualHost{identifier: identifier}
	v.Unlock()
}

func (v *virtualHosts) deleteHost(host string) {
	v.Lock()
	delete(v.mapping, host)
	v.Unlock()
}

// getIdentifier returns the identifier associated with the given host
func (v *virtualHosts) getIdentifier(host string) (string, bool) {
	v.Lock()
	ht, ok := v.mapping[host]
	v.Unlock()

	if !ok {
		return "", false
	}

	return ht.identifier, true
}

// getHost returns the host associated with the given identifier
func (v *virtualHosts) getHost(identifier string) (string, bool) {
	v.Lock()
	defer v.Unlock()

	for hostname, hst := range v.mapping {
		if hst.identifier == identifier {
			return hostname, true
		}
	}

	return "", false
}
