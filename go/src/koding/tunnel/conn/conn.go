// Conn satisfies the net.conn interface. It has support for reconnection and
// has callback  functions that are called when a reconnect or disconnect
// happens.
package conn

import (
	"io"
	"log"
	"net"
	"strings"
	"time"
)

type Conn struct {
	nc net.Conn

	// interval defines the reconnect interval when the connection is closed
	interval time.Duration

	// onReconnectFunc is called after a successfull reconnect
	onReconnectHandlers []func()

	// onDisconnectFunc is called after a socket disconnection
	onDisconnectHandlers []func()

	// reconnectEnabled is a trigger that enables reconnection when the
	// established connection is close.
	reconnectEnabled bool
}

func New(nc net.Conn, reconnect bool) *Conn {
	return &Conn{
		nc:               nc,
		interval:         time.Second * 3,
		reconnectEnabled: reconnect,
	}
}

func Dial(addr string, reconnect bool) (*Conn, error) {
	conn, err := net.Dial("tcp", addr)
	if err != nil {
		return nil, err
	}

	return New(conn, reconnect), nil
}

func (c *Conn) Read(buf []byte) (int, error) {
	n, err := c.nc.Read(buf)
	errCheck := c.check(err)

	return n, errCheck
}

func (c *Conn) Write(buf []byte) (int, error) {
	n, err := c.nc.Write(buf)
	errCheck := c.check(err)

	return n, errCheck
}

func (c *Conn) Close() error {
	return c.nc.Close()
}

func (c *Conn) LocalAddr() net.Addr {
	return c.nc.LocalAddr()
}

func (c *Conn) RemoteAddr() net.Addr {
	return c.nc.RemoteAddr()
}

func (c *Conn) SetDeadline(t time.Time) error {
	return c.nc.SetDeadline(t)
}

func (c *Conn) SetReadDeadline(t time.Time) error {
	return c.nc.SetReadDeadline(t)
}

func (c *Conn) SetWriteDeadline(t time.Time) error {
	return c.nc.SetWriteDeadline(t)
}

// check checks whether the error is a socketClosed err. If yes it calls the
// stored OnDisconnect functions and tries to reconnect if reconnect is
// enabled.
func (c *Conn) check(err error) error {
	if err == nil {
		return err
	}

	if !c.socketClosed(err) {
		return err
	}

	c.callOnDisconnectHandlers()

	// return if we don't want to reconnect
	if !c.reconnectEnabled {
		return err
	}

	c.reconnect()
	return nil

}

// reconnect tries to reconnect in intervals defined by Conn.interval.
// It is blocking and tries to reconnect forever. After a successfull
// reconnection, Conn invokies c.onReconnectFunc if any set.
func (c *Conn) reconnect() {
	var conn net.Conn
	var err error

	for {
		log.Println("reconnecting to", c.RemoteAddr().String())
		conn, err = c.dial()
		if err == nil {
			log.Println("reconnected")
			break
		}

		time.Sleep(c.interval)
	}

	c.nc = conn
	c.callOnReconnectHandlers()
}

// OnReconnect registers the given handler to be invoked for each successfull
// reconnection.
func (c *Conn) OnReconnect(handler func()) {
	c.onReconnectHandlers = append(c.onReconnectHandlers, handler)
}

// OnDisconnect registers the given handler to be invoked after a socket
// disconnection.
func (c *Conn) OnDisconnect(handler func()) {
	c.onDisconnectHandlers = append(c.onDisconnectHandlers, handler)
}

// callOnReconnectHandlers runs the registered reconnect handlers
func (c *Conn) callOnReconnectHandlers() {
	for _, handler := range c.onReconnectHandlers {
		// don't start them in a go routine, it can mess up the underlying tcp
		// connection.
		handler()
	}
}

// callOnDisconnectHandlers runs the registered disconnect handlers
func (c *Conn) callOnDisconnectHandlers() {
	for _, handler := range c.onDisconnectHandlers {
		// don't start them in a go routine, it can mess up the underlying tcp
		// connection.
		handler()
	}
}

func (c *Conn) dial() (net.Conn, error) {
	return net.Dial(c.RemoteAddr().Network(), c.RemoteAddr().String())
}

// socketClosed is an convenient helper to check if the underlying socket
// connection is closed.
func (c *Conn) socketClosed(err error) bool {
	if err == nil {
		return false
	}

	errString := err.Error()
	if err == io.EOF ||
		strings.HasSuffix(errString, "use of closed network connection") ||
		strings.HasSuffix(errString, "broken pipe") ||
		strings.HasSuffix(errString, "connection reset by peer") {
		return true
	}

	return false
}
