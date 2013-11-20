package tunnel

import (
	"bufio"
	"errors"
	"fmt"
	"io"
	"log"
	"net"
	"net/http"
	"strings"
	"time"
)

var ErrSocketClosed = errors.New("socket closed")

// TunnelConn satisfies the net.conn interface. It reconnects when the
// connection is closed.
type TunnelConn struct {
	conn net.Conn

	// interval defines the reconnect interval when the connection is closed
	interval time.Duration
}

func NewTunnelConn(addr string) *TunnelConn {
	conn, err := net.Dial("tcp", addr)
	if err != nil {
		log.Fatalf("NewTunnelConn %s\n", err)
	}

	return &TunnelConn{
		conn:     conn,
		interval: time.Second * 3,
	}
}

func (t *TunnelConn) Read(buf []byte) (int, error) {
	n, err := t.conn.Read(buf)
	if err == nil {
		return n, err
	}

	if !t.socketClosed(err) {
		return n, err
	}

	t.reconnect()

	return n, nil
}

func (t *TunnelConn) Write(buf []byte) (int, error) {
	return t.conn.Write(buf)
}

func (t *TunnelConn) Close() error {
	return t.conn.Close()
}

func (t *TunnelConn) LocalAddr() net.Addr {
	return t.conn.LocalAddr()
}

func (t *TunnelConn) RemoteAddr() net.Addr {
	return t.conn.RemoteAddr()
}

func (t *TunnelConn) SetDeadline(deadline time.Time) error {
	return t.conn.SetDeadline(deadline)
}

func (t *TunnelConn) SetReadDeadline(deadline time.Time) error {
	return t.conn.SetReadDeadline(deadline)
}

func (t *TunnelConn) SetWriteDeadline(deadline time.Time) error {
	return t.conn.SetWriteDeadline(deadline)
}

func (t *TunnelConn) reconnect() {
	var conn net.Conn
	var err error

	for {
		log.Println("reconnecting to", t.RemoteAddr().String())
		conn, err = t.dial()
		if err == nil {
			log.Println("reconnected")
			break
		}

		time.Sleep(t.interval)
	}

	t.conn = conn
}

func (t *TunnelConn) dial() (net.Conn, error) {
	return net.Dial(t.RemoteAddr().Network(), t.RemoteAddr().String())
}

func (t *TunnelConn) socketClosed(err error) bool {
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

func (t *TunnelConn) Connect(path string) error {
	remoteAddr := fmt.Sprintf("http://%s%s", t.conn.RemoteAddr(), path)
	req, err := http.NewRequest("CONNECT", remoteAddr, nil)
	if err != nil {
		return fmt.Errorf("CONNECT", err)
	}

	// req.Header.Set("username", "fatih")
	req.Write(t.conn)

	resp, err := http.ReadResponse(bufio.NewReader(t.conn), req)
	if err != nil {
		return fmt.Errorf("read response", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 && resp.Status != Connected {
		return fmt.Errorf("Non-200 response from proxy server: %s", resp.Status)
	}

	return nil
}
