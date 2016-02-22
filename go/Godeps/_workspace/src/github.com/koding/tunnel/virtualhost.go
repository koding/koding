package tunnel

import (
	"sync"
)

type vhostStorage interface {
	// AddHost adds the given host and identifier to the storage
	AddHost(host, identifier string)

	// DeleteHost deletes the given host
	DeleteHost(host string)

	// GetHost returns the host name for the given identifier
	GetHost(identifier string) (string, bool)

	// GetIdentifier returns the identifier for the given host
	GetIdentifier(host string) (string, bool)
}

type virtualHost struct {
	identifier string
}

// virtualHosts is used for mapping host to users example: host
// "fs-1-fatih.kd.io" belongs to user "arslan"
type virtualHosts struct {
	mapping map[string]*virtualHost
	sync.Mutex
}

// newVirtualHosts provides an in memory virtual host storage for mapping
// virtual hosts to identifiers.
func newVirtualHosts() *virtualHosts {
	return &virtualHosts{
		mapping: make(map[string]*virtualHost),
	}
}

func (v *virtualHosts) AddHost(host, identifier string) {
	v.Lock()
	v.mapping[host] = &virtualHost{identifier: identifier}
	v.Unlock()
}

func (v *virtualHosts) DeleteHost(host string) {
	v.Lock()
	delete(v.mapping, host)
	v.Unlock()
}

// GetIdentifier returns the identifier associated with the given host
func (v *virtualHosts) GetIdentifier(host string) (string, bool) {
	v.Lock()
	ht, ok := v.mapping[host]
	v.Unlock()

	if !ok {
		return "", false
	}

	return ht.identifier, true
}

// GetHost returns the host associated with the given identifier
func (v *virtualHosts) GetHost(identifier string) (string, bool) {
	v.Lock()
	defer v.Unlock()

	for hostname, hst := range v.mapping {
		if hst.identifier == identifier {
			return hostname, true
		}
	}

	return "", false
}
