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
	// Network represents address network like "ip", "kite" etc.
	Network string `json:"network"`

	// Val stores a string representation of an address.
	Value string `json:"value"`

	// UpdatedAt stores the address update time.
	UpdatedAt time.Time `json:"updated_at"`
}

// String return a string form of stored address.
func (a *Addr) String() string { return a.Network + " address " + a.Value }

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
		if ab.addrs[i].Network == a.Network && ab.addrs[i].Value == a.Value && ab.addrs[i].UpdatedAt.Before(a.UpdatedAt) {
			ab.addrs[i].UpdatedAt = a.UpdatedAt
		}
	}

	ab.addrs = append(ab.addrs, a)
}

// Has reports whether provided address is stored in address book or not.
func (ab *AddrBook) Has(a Addr) bool {
	ab.mu.RLock()
	defer ab.mu.RUnlock()

	for i := range ab.addrs {
		if ab.addrs[i].Network == a.Network && ab.addrs[i].Value == a.Value {
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
		timeok = !ab.addrs[i].UpdatedAt.Before(t)
		if network == ab.addrs[i].Network && timeok {
			addr = &ab.addrs[i]
			t = ab.addrs[i].UpdatedAt
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
