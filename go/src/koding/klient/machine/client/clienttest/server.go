package clienttest

import (
	"sync"
	"time"

	"koding/klient/machine"
	"koding/klient/machine/client"
)

// DynamicOpts creates test-friendly options for dynamic client.
func DynamicOpts(s *Server, b *Builder) client.DynamicOpts {
	return client.DynamicOpts{
		AddrFunc:        s.AddrFunc(),
		AddrSetFunc:     func(_ machine.Addr) {},
		Builder:         b,
		DynAddrInterval: 10 * time.Millisecond,
		PingInterval:    50 * time.Millisecond,
	}
}

// TurnOnAddr returns address that "starts" test machine.
func TurnOnAddr() machine.Addr {
	return machine.Addr{
		Network:   "on",
		Value:     "0",
		UpdatedAt: time.Now(),
	}
}

// TurnOffAddr returns address that "stops" test machine.
func TurnOffAddr() machine.Addr {
	return machine.Addr{
		Network:   "off",
		Value:     "0",
		UpdatedAt: time.Now(),
	}
}

// Server simulates the real server.
type Server struct {
	mu   sync.Mutex
	addr machine.Addr
}

// AddrFunc returns client.DynamicAddrFunc that can be used as addresses source.
func (s *Server) AddrFunc() client.DynamicAddrFunc {
	return func(network string) (machine.Addr, error) {
		s.mu.Lock()
		defer s.mu.Unlock()

		if network == s.addr.Network {
			return s.addr, nil
		}

		return machine.Addr{}, machine.ErrAddrNotFound
	}
}

// TurnOn simulates on-line server.
func (s *Server) TurnOn() {
	s.mu.Lock()
	defer s.mu.Unlock()

	value := s.addr.Value
	if value == "" {
		value = "0" // initial address.
	}

	s.addr = machine.Addr{
		Network: "on",
		Value:   value,
	}
}

// TurnOff simulates off-line server.
func (s *Server) TurnOff() {
	s.mu.Lock()
	defer s.mu.Unlock()

	s.addr.Network = "off"
}

// ChangeAddr generates a new address for server.
func (s *Server) ChangeAddr() {
	s.mu.Lock()
	defer s.mu.Unlock()

	s.addr.Value += "0"
}
