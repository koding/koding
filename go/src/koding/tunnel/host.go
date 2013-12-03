package tunnel

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
	defer v.Unlock()

	v.mapping[host] = &virtualHost{identifier: identifier}
}

func (v *virtualHosts) deleteHost(host string) {
	v.Lock()
	defer v.Unlock()

	delete(v.mapping, host)
}

// getIdentifier returns the identifier associated with the given host
func (v *virtualHosts) getIdentifier(host string) (string, bool) {
	v.Lock()
	defer v.Unlock()

	ht, ok := v.mapping[host]
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
