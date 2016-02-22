package tigertonic

import (
	"net"
	"sync"
)

// Conn is just a net.Conn that accounts for itself so the listener can be
// stopped gracefully.
type Conn struct {
	net.Conn
	once sync.Once
	wg   *sync.WaitGroup
}

// Close closes the connection and notifies the listener that accepted it.
func (c *Conn) Close() (err error) {
	err = c.Conn.Close()
	c.once.Do(c.wg.Done)
	return
}

// Listener is just a net.Listener that accounts for connections it accepts
// so it can be stopped gracefully.
type Listener struct {
	net.Listener
	wg *sync.WaitGroup
}

// Accept waits for, accounts for, and returns the next connection to the
// listener.
func (l *Listener) Accept() (c net.Conn, err error) {
	c, err = l.Listener.Accept()
	if nil != err {
		return
	}
	l.wg.Add(1)
	c = &Conn{
		Conn: c,
		wg:   l.wg,
	}
	return
}

// Close closes the listener.  It does not wait for all connections accepted
// through the listener to be closed.
func (l *Listener) Close() (err error) {
	err = l.Listener.Close()
	return
}
