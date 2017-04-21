package machine

import (
	"encoding/json"
	"errors"
	"net"
	"sync"
	"time"
)

var (
	// ErrAddrNotFound indicates that provided address does not exist.
	ErrAddrNotFound = errors.New("address not found")
)

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
func (a Addr) String() string { return a.Network + " address " + a.Value }

// AddrBook stores and manages multiple machine addresses. Each machine can
// can change its end point address over time. This can store all of these
// addresses which allows to bind old resources with new address.
type AddrBook struct {
	MaxSize int // Max size of each stored address types, 0 means unlimited.

	mu    sync.RWMutex
	addrs []Addr
}

var (
	_ json.Marshaler   = (*AddrBook)(nil)
	_ json.Unmarshaler = (*AddrBook)(nil)
)

// Add adds new address to address book. If provided address already exists, its
// updated time will be updated. Empty addresses will not be added.
//
// Moreover, if provided IP address doesn't match IPv4 or IPv6 schema, its
// network will be changed to `tunnel`. If provided address contains port part
// and has IP network, there will be two addresses added - one with `ip` network
// and one with `tcp` network.
func (ab *AddrBook) Add(a Addr) {
	var isIP = func(val string) bool {
		return net.ParseIP(val) != nil // ParseIP returns nil if IP is invalid.
	}

	if a.Network == "" || a.Value == "" {
		return
	}

	if a.Network != "ip" || isIP(a.Value) {
		ab.add(a)
		return
	}

	if host, _, err := net.SplitHostPort(a.Value); err == nil && isIP(host) {
		ab.add(Addr{
			Network: "ip",
			Value:   host,
		})
		ab.add(Addr{
			Network: "tcp",
			Value:   a.Value,
		})
		return
	}

	ab.add(Addr{
		Network: "tunnel",
		Value:   a.Value,
	})
}

func (ab *AddrBook) add(a Addr) {
	ab.mu.Lock()
	defer ab.mu.Unlock()

	// If Addr already exists, update only its Updated field.
	for i := range ab.addrs {
		if ab.addrs[i].Network != a.Network || ab.addrs[i].Value != a.Value {
			continue
		}

		if ab.addrs[i].UpdatedAt.Before(a.UpdatedAt) {
			ab.addrs[i].UpdatedAt = a.UpdatedAt
		}

		return
	}

	ab.addrs = append(ab.addrs, a)
	ab.keepMaxSize(a)
}

func (ab *AddrBook) keepMaxSize(a Addr) {
	if ab.MaxSize <= 0 || len(ab.addrs) <= ab.MaxSize || len(ab.addrs) == 0 {
		return
	}

	size := 0
	for i := range ab.addrs {
		if a.Network == ab.addrs[i].Network {
			size++
		}
	}

	for ab.MaxSize < size {
		// Remove oldest entry.
		t, i := ab.addrs[0].UpdatedAt, 0
		for j := range ab.addrs {
			if a.Network == ab.addrs[j].Network && t.After(ab.addrs[j].UpdatedAt) {
				t, i = ab.addrs[j].UpdatedAt, j
			}
		}

		ab.addrs = append(ab.addrs[:i], ab.addrs[i+1:]...)
		size--
	}
}

// Updated reports when provided address was updated. It returns ErrAddrNotFound
// when address is not found.
func (ab *AddrBook) Updated(a Addr) (time.Time, error) {
	ab.mu.RLock()
	defer ab.mu.RUnlock()

	for i := range ab.addrs {
		if ab.addrs[i].Network == a.Network && ab.addrs[i].Value == a.Value {
			return ab.addrs[i].UpdatedAt, nil
		}
	}

	return time.Time{}, ErrAddrNotFound
}

// All returns a copy of all addresses stored in Address book.
func (ab *AddrBook) All() (cp []Addr) {
	ab.mu.RLock()
	defer ab.mu.RUnlock()

	for i := range ab.addrs {
		cp = append(cp, ab.addrs[i])
	}

	return cp
}

// Latest returns the latest known address for a given network. If no address
// is found, ErrAddrNotFound error is returned.
func (ab *AddrBook) Latest(network string) (Addr, error) {
	ab.mu.RLock()
	defer ab.mu.RUnlock()

	t, addr := time.Time{}, (*Addr)(nil)
	for i := range ab.addrs {
		timeok := !ab.addrs[i].UpdatedAt.Before(t)
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
	ab.mu.Lock()
	defer ab.mu.Unlock()

	return json.Unmarshal(data, &ab.addrs)
}
