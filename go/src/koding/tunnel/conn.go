package tunnel

import (
	"errors"
	"io"
	"log"
	"net"
	"strings"
	"time"
)

var ErrSocketClosed = errors.New("socket closed")

// clientConn satisfies the net.conn interface. If reconnectEnabled is true,
// it reconnects when the connection is closed.
type clientConn struct {
	conn net.Conn

	// interval defines the reconnect interval when the connection is closed
	interval time.Duration

	// onReconnectFunc is called after a successfull reconnect
	onReconnectFunc func()

	// reconnectEnabled is a trigger that enables reconnection when the
	// established connection is close.
	reconnectEnabled bool
}

func newClientConn(addr string, reconnect bool) *clientConn {
	conn, err := net.Dial("tcp", addr)
	if err != nil {
		log.Fatalf("newClientConn %s\n", err)
	}

	return &clientConn{
		conn:             conn,
		interval:         time.Second * 3,
		reconnectEnabled: reconnect,
	}
}

func (c *clientConn) Read(buf []byte) (int, error) {
	n, err := c.conn.Read(buf)
	if err == nil {
		return n, err
	}

	if !c.reconnectEnabled {
		return n, err
	}

	if !c.socketClosed(err) {
		return n, err
	}

	c.reconnect()

	return n, nil
}

func (c *clientConn) Write(buf []byte) (int, error) {
	return c.conn.Write(buf)
}

func (c *clientConn) Close() error {
	return c.conn.Close()
}

func (c *clientConn) LocalAddr() net.Addr {
	return c.conn.LocalAddr()
}

func (c *clientConn) RemoteAddr() net.Addr {
	return c.conn.RemoteAddr()
}

func (c *clientConn) SetDeadline(t time.Time) error {
	return c.conn.SetDeadline(t)
}

func (c *clientConn) SetReadDeadline(t time.Time) error {
	return c.conn.SetReadDeadline(t)
}

func (c *clientConn) SetWriteDeadline(t time.Time) error {
	return c.conn.SetWriteDeadline(t)
}

// reconnect tries to reconnect in intervals defined by clientConn.interval.
// It is blocking and tries to reconnect forever. After a successfull
// reconnection, clientConn invokies c.onReconnectFunc if any set.
func (c *clientConn) reconnect() {
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

	c.conn = conn

	if c.onReconnectFunc != nil {
		// call it when there is a function available
		c.onReconnectFunc()
	}
}

// onReconnect calls the given function f for each successfull reconnection.
func (c *clientConn) onReconnect(f func()) {
	c.onReconnectFunc = f
}

func (c *clientConn) dial() (net.Conn, error) {
	return net.Dial(c.RemoteAddr().Network(), c.RemoteAddr().String())
}

func (c *clientConn) socketClosed(err error) bool {
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
