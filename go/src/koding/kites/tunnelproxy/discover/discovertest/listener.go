package discovertest

import (
	"net"
	"net/http"
	"net/http/httptest"
	"sync"
)

// TODO(rjeczalik): move to some top-level testing package

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

// Listen gives new Listener that listening on the given
// network and address.
func Listen(network, addr string) (*Listener, error) {
	l, err := net.Listen(network, addr)
	if err != nil {
		return nil, err
	}
	return NewListener(l), nil
}

// NewServer works like httptest.NewServer, but it waits until
// the HTTP server actually started listening on connections.
func NewServer(h http.Handler) (*httptest.Server, error) {
	l, err := Listen("tcp", ":0")
	if err != nil {
		return nil, err
	}

	s := httptest.NewUnstartedServer(h)
	s.Listener = l
	s.Start()

	l.Wait()

	return s, nil
}
