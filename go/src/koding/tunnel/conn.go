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

// ClientConn satisfies the net.conn interface. It reconnects when the
// connection is closed.
type ClientConn struct {
	conn net.Conn

	// interval defines the reconnect interval when the connection is closed
	interval time.Duration

	// kind defines how to
}

func NewClientConn(addr string) *ClientConn {
	conn, err := net.Dial("tcp", addr)
	if err != nil {
		log.Fatalf("NewClientConn %s\n", err)
	}

	return &ClientConn{
		conn:     conn,
		interval: time.Second * 3,
	}
}

func (c *ClientConn) Read(buf []byte) (int, error) {
	n, err := c.conn.Read(buf)
	if err == nil {
		return n, err
	}

	if !c.socketClosed(err) {
		return n, err
	}

	c.reconnect()

	return n, nil
}

func (c *ClientConn) Write(buf []byte) (int, error) {
	return c.conn.Write(buf)
}

func (c *ClientConn) Close() error {
	return c.conn.Close()
}

func (c *ClientConn) LocalAddr() net.Addr {
	return c.conn.LocalAddr()
}

func (c *ClientConn) RemoteAddr() net.Addr {
	return c.conn.RemoteAddr()
}

func (c *ClientConn) SetDeadline(t time.Time) error {
	return c.conn.SetDeadline(t)
}

func (c *ClientConn) SetReadDeadline(t time.Time) error {
	return c.conn.SetReadDeadline(t)
}

func (c *ClientConn) SetWriteDeadline(t time.Time) error {
	return c.conn.SetWriteDeadline(t)
}

func (c *ClientConn) reconnect() {
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
}

func (c *ClientConn) dial() (net.Conn, error) {
	return net.Dial(c.RemoteAddr().Network(), c.RemoteAddr().String())
}

func (c *ClientConn) socketClosed(err error) bool {
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
