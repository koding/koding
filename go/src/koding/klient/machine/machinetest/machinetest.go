package machinetest

import (
	"context"
	"fmt"
	"sync"
	"sync/atomic"
	"time"

	"koding/klient/machine"
)

// DynamicClientOpts creates test-friendly options for dynamic client.
func DynamicClientOpts(s *Server, b *NilBuilder) machine.DynamicClientOpts {
	return machine.DynamicClientOpts{
		AddrFunc:        s.AddrFunc(),
		Builder:         b,
		DynAddrInterval: 10 * time.Millisecond,
		PingInterval:    50 * time.Millisecond,
	}
}

// Server simulates the real server.
type Server struct {
	mu   sync.Mutex
	addr machine.Addr
}

// AddrFunc returns machine.DynamicAddrFunc that can be used as addresses source.
func (s *Server) AddrFunc() machine.DynamicAddrFunc {
	return func(string) (machine.Addr, error) {
		s.mu.Lock()
		defer s.mu.Unlock()

		return s.addr, nil
	}
}

// TurnOn simulates on-line server.
func (s *Server) TurnOn() {
	s.mu.Lock()
	defer s.mu.Unlock()

	value := s.addr.Val
	if value == "" {
		value = "0" // initial address.
	}

	s.addr = machine.Addr{
		Net: "on",
		Val: value,
	}
}

// TurnOff simulates off-line server.
func (s *Server) TurnOff() {
	s.mu.Lock()
	defer s.mu.Unlock()

	s.addr.Net = "off"
}

// ChangeAddr generates a new address for server.
func (s *Server) ChangeAddr() {
	s.mu.Lock()
	defer s.mu.Unlock()

	s.addr.Val += "0"
}

// NilBuilder uses Server logic to build nil clients.
type NilBuilder struct {
	buildsN int64
	ch      chan struct{}
}

// NewNilBuilder creates a new NilBuilder object.
func NewNilBuilder() *NilBuilder {
	return &NilBuilder{
		ch: make(chan struct{}),
	}
}

// Ping returns machine statuses based on Server response.
func (*NilBuilder) Ping(dynAddr machine.DynamicAddrFunc) (machine.Status, machine.Addr, error) {
	if dynAddr == nil {
		panic("nil dynamic function generator")
	}

	addr, err := dynAddr("")
	if err != nil {
		return machine.Status{}, addr, err
	}

	status := machine.Status{}
	switch addr.Net {
	case "on":
		status.State = machine.StateOnline
	case "off":
		status.State = machine.StateOffline
	}

	return status, addr, nil
}

// Build creates a nil client and increases builds counter.
func (n *NilBuilder) Build(_ context.Context, _ machine.Addr) machine.Client {
	go func() {
		atomic.AddInt64(&n.buildsN, 1)
		n.ch <- struct{}{}
	}()

	return nil
}

// WaitForBuild waits for invocation of Build method. It times out after
// specified duration.
func (n *NilBuilder) WaitForBuild(timeout time.Duration) error {
	select {
	case <-n.ch:
		return nil
	case <-time.After(timeout):
		return fmt.Errorf("timed out after %s", timeout)
	}
}

// BuildsCount returns how many times Build method was invoked.
func (n *NilBuilder) BuildsCount() int {
	return int(atomic.LoadInt64(&n.buildsN))
}
