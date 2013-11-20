package tunnel

import (
	"fmt"
	// "io"
	"net"
	"time"
)

// reconnectConn satisfies the net.conn interface. It reconnects when the
// connection is closed.
type reconnectConn struct {
	conn net.Conn

	// interval defines the reconnect interval when the connection is closed
	interval time.Duration
}

func newReconnectConn(conn net.Conn, interval time.Duration) *reconnectConn {
	return &reconnectConn{conn: conn}
}

func (r *reconnectConn) Read(buf []byte) (int, error) {
	n, err := r.conn.Read(buf)
	if err == nil {
		return n, err
	}

	fmt.Println("read", err)

	errReconnect := r.reconnect()
	if errReconnect != nil {
		fmt.Println("reconnect", errReconnect)
		return n, err
	}

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

func (r *reconnectConn) reconnect() error {
	conn, err := net.Dial("tcp", r.RemoteAddr().String())
	if err != nil {
		return err
	}

	r.conn = conn
	return nil
}
