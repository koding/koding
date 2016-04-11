package discovertest

import (
	"net"
	"sync"
)

// Listener is a listener that allows waiting for a server loop.
//
// Typically any code that calls `go http.Serve` is inherently racy
// between client issuing first request and http.Serve entering its
// serve loop.
//
// With a *Listener the access to a net.Listener can be synchronized
// with (*Listener).Wait call.
type Listener struct {
	net.Listener
	sync.WaitGroup
	sync.Once
}

var _ net.Listener = (*Listener)(nil)

// NewListener wraps net.Listener with a *Listener value.
func NewListener(l net.Listener) *Listener {
	lis := &Listener{
		Listener: l,
	}

	lis.Add(1)

	return lis
}

// Accept implements the net.Listener interface.
//
// Upon first call to Accept it signals ready to all callers
// waiting on l.WaitGroup.
func (l *Listener) Accept() (net.Conn, error) {
	l.Do(l.Done)

	return l.Listener.Accept()
}
