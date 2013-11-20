package tunnel

import (
	"errors"
	"io"
	"net"
	"strings"
	"time"
)

var ErrSocketClosed = errors.New("socket closed")

// reconnectConn satisfies the net.conn interface. It reconnects when the
// connection is closed.
type reconnectConn struct {
	conn net.Conn

	// interval defines the reconnect interval when the connection is closed
	interval time.Duration
}

func newReconnectConn(conn net.Conn, interval time.Duration) *reconnectConn {
	if interval == 0 {
		interval = time.Second * 3
	}

	return &reconnectConn{
		conn:     conn,
		interval: interval,
	}
}

func (r *reconnectConn) Read(buf []byte) (int, error) {
	n, err := r.conn.Read(buf)
	if err == nil {
		return n, err
	}

	if !r.socketClosed(err) {
		return n, err
	}

	r.reconnect()

	return n, nil
}

func (r *reconnectConn) Write(buf []byte) (int, error) {
	return r.conn.Write(buf)
}

func (r *reconnectConn) Close() error {
	return r.conn.Close()
}

func (r *reconnectConn) LocalAddr() net.Addr {
	return r.conn.LocalAddr()
}

func (r *reconnectConn) RemoteAddr() net.Addr {
	return r.conn.RemoteAddr()
}

func (r *reconnectConn) SetDeadline(t time.Time) error {
	return r.conn.SetDeadline(t)
}

func (r *reconnectConn) SetReadDeadline(t time.Time) error {
	return r.conn.SetReadDeadline(t)
}

func (r *reconnectConn) SetWriteDeadline(t time.Time) error {
	return r.conn.SetWriteDeadline(t)
}

func (r *reconnectConn) reconnect() {
	var conn net.Conn
	var err error

	for {
		conn, err = r.dial()
		if err == nil {
			break
		}

		time.Sleep(r.interval)
	}

	r.conn = conn
}

func (r *reconnectConn) dial() (net.Conn, error) {
	return net.Dial(r.RemoteAddr().Network(), r.RemoteAddr().String())
}

func (r *reconnectConn) socketClosed(err error) bool {
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
