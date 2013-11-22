package conn

import (
	"io"
	"log"
	"net"
	"strings"
	"time"
)

// Conn satisfies the net.conn interface. If reconnectEnabled is true,
// it reconnects when the connection is closed.
type Conn struct {
	nc net.Conn

	// interval defines the reconnect interval when the connection is closed
	interval time.Duration

	// onReconnectFunc is called after a successfull reconnect
	onReconnectFunc func()

	// onDisconnectFunc is called after a successfull reconnect
	onDisconnectFunc func()

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

func Dial(addr string, reconnect bool) *Conn {
	conn, err := net.Dial("tcp", addr)
	if err != nil {
		log.Fatalf("dial %s\n", err)
	}

	return New(conn, reconnect)
}

func (c *Conn) Read(buf []byte) (int, error) {
	n, err := c.nc.Read(buf)
	if err == nil {
		return n, err
	}

	if !c.socketClosed(err) {
		return n, err
	}

	// we are disconnected, invoke any onDisconnect handler if any available.
	if c.onDisconnectFunc != nil {
		c.onDisconnectFunc()
	}

	// return if we don't want to reconnect
	if !c.reconnectEnabled {
		return n, err
	}

	c.reconnect()
	return n, nil
}

func (c *Conn) Write(buf []byte) (int, error) {
	n, err := c.nc.Write(buf)
	return n, err
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

	if c.onReconnectFunc != nil {
		// call it when there is a function available
		c.onReconnectFunc()
	}
}

// onReconnect calls the given function f for each successfull reconnection.
func (c *Conn) OnReconnect(f func()) {
	c.onReconnectFunc = f
}

func (c *Conn) OnDisconnect(f func()) {
	c.onDisconnectFunc = f
}

func (c *Conn) dial() (net.Conn, error) {
	return net.Dial(c.RemoteAddr().Network(), c.RemoteAddr().String())
}

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
