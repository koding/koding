package tunnel

import (
	"bufio"
	"fmt"
	"log"
	"net"
	"net/http"
	"time"
)

type tunnelConn struct {
	clientConn
}

func newTunnelConn(addr string, serverMsg *ServerMsg) *tunnelConn {
	conn, err := net.Dial("tcp", addr)
	if err != nil {
		log.Fatalf("newTunnelConn %s\n", err)
	}

	t := &tunnelConn{}
	t.conn = conn
	t.interval = time.Second * 3

	err = t.connect(serverMsg)
	if err != nil {
		log.Fatalln("newTunnelConn", err)
	}

	return t
}

func (c *tunnelConn) connect(serverMsg *ServerMsg) error {
	remoteAddr := fmt.Sprintf("http://%s%s", c.conn.RemoteAddr(), TunnelPath)
	req, err := http.NewRequest("CONNECT", remoteAddr, nil)
	if err != nil {
		return fmt.Errorf("CONNECT", err)
	}

	req.Header.Set("protocol", serverMsg.Protocol)
	req.Header.Set("tunnelID", serverMsg.TunnelID)
	req.Header.Set("username", serverMsg.Username)
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
