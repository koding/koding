package machine

import (
	"encoding/json"
	"errors"
	"sync"
	"time"
)

var (
	// ErrAddrNotFound indicates that provided address does not exist.
	ErrAddrNotFound = errors.New("address not found")
)

// IsAddrNotFound is a helper function that checks if provided error describes
// missing address.
func IsAddrNotFound(err error) bool {
	return err == ErrAddrNotFound
}

// Addr satisfies net.Addr interface. It stores external machine address and
// a time-stamp which indicates when the address was last seen being valid.
type Addr struct {
	// Net represents address network like "ip", "kite" etc.
	Net string `json:"network"`

	// Val stores a string representation of an address.
	Val string `json:"value"`

	// Updated stores the address update time.
	Updated time.Time `json:"updated"`
}

// Network returns the name of the network.
func (a *Addr) Network() string { return a.Net }

// String return a string form of stored address.
func (a *Addr) String() string { return a.Val }

// AddrBook stores and manages multiple machine addresses. Each machine can
// can change its end point address over time. This can store all of these
// addresses which allows to bind old resources with new address.
type AddrBook struct {
	mu    sync.RWMutex
	addrs []Addr
}

// Add adds new address to address book. If provided address already exists, its
// updated time will be updated.
func (ab *AddrBook) Add(a Addr) {
	ab.mu.Lock()
	defer ab.mu.Unlock()

	// If Addr already exists, update only its Updated field.
	for i := range ab.addrs {
		if ab.addrs[i].Net == a.Net && ab.addrs[i].Val == a.Val && ab.addrs[i].Updated.Before(a.Updated) {
			ab.addrs[i].Updated = a.Updated
		}
	}

	ab.addrs = append(ab.addrs, a)
}

// Has reports whether provided address is stored in address book or not.
func (ab *AddrBook) Has(a Addr) bool {
	ab.mu.RLock()
	defer ab.mu.RUnlock()

	for i := range ab.addrs {
		if ab.addrs[i].Net == a.Net && ab.addrs[i].Val == a.Val {
			return true
		}
	}

	return false
}

// Latest returns the latest known address for a given network. If no address
// is found, ErrAddrNotFound error is returned.
func (ab *AddrBook) Latest(network string) (Addr, error) {
	ab.mu.RLock()
	defer ab.mu.RUnlock()

	t, addr, timeok := time.Time{}, (*Addr)(nil), false
	for i := range ab.addrs {
		timeok = t.Before(ab.addrs[i].Updated) || t.Equal(ab.addrs[i].Updated)
		if network == ab.addrs[i].Net && timeok {
			addr = &ab.addrs[i]
			t = ab.addrs[i].Updated
		}
	}

	if addr == nil {
		return Addr{}, ErrAddrNotFound
	}

	return *addr, nil
}

// MarshalJSON satisfies json.Marshaler interface. It safely marshals address
// book private data to JSON format.
func (ab *AddrBook) MarshalJSON() ([]byte, error) {
	ab.mu.RLock()
	defer ab.mu.RUnlock()

	return json.Marshal(ab.addrs)
}

// UnmarshalJSON satisfies json.Unmarshaler interface. It is used to unmarshal
// data into private address book fields.
func (ab *AddrBook) UnmarshalJSON(data []byte) error {
	return json.Unmarshal(data, &ab.addrs)
}
