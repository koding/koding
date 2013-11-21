package tunnel

import (
	"bufio"
	"fmt"
	"log"
	"net"
	"net/http"
	"time"
)

type TunnelConn struct {
	ClientConn
}

func NewTunnelConn(addr, protocol, tunnelID string) *TunnelConn {
	conn, err := net.Dial("tcp", addr)
	if err != nil {
		log.Fatalf("NewTunnelConn %s\n", err)
	}

	t := &TunnelConn{}
	t.conn = conn
	t.interval = time.Second * 3

	err = t.connect(protocol, tunnelID)
	if err != nil {
		log.Fatalln("NewTunnelConn", err)
	}

	return t
}

func (c *TunnelConn) connect(protocol, tunnelID string) error {
	remoteAddr := fmt.Sprintf("http://%s%s", c.conn.RemoteAddr(), TunnelPath)
	req, err := http.NewRequest("CONNECT", remoteAddr, nil)
	if err != nil {
		return fmt.Errorf("CONNECT", err)
	}

	req.Header.Set("protocol", protocol)
	req.Header.Set("tunnelID", tunnelID)
	req.Write(c.conn)

	resp, err := http.ReadResponse(bufio.NewReader(c.conn), req)
	if err != nil {
		return fmt.Errorf("read response", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 && resp.Status != Connected {
		return fmt.Errorf("Non-200 response from proxy server: %s", resp.Status)
	}

	return nil
}
