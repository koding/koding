package tunnel

import (
	"bufio"
	"fmt"
	"log"
	"net"
	"net/http"
	"time"
)

type controlConn struct {
	clientConn
}

func newControlConn(addr, username string) *controlConn {
	conn, err := net.Dial("tcp", addr)
	if err != nil {
		log.Fatalf("newControlConn %s\n", err)
	}

	c := &controlConn{}
	c.conn = conn
	c.interval = time.Second * 3

	err = c.connect(username)
	if err != nil {
		log.Fatalln("newControlConn", err)
	}

	return c
}

func (c *controlConn) connect(username string) error {
	remoteAddr := fmt.Sprintf("http://%s%s", c.conn.RemoteAddr(), ControlPath)
	req, err := http.NewRequest("CONNECT", remoteAddr, nil)
	if err != nil {
		return fmt.Errorf("CONNECT", err)
	}

	req.Header.Set("username", username)
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
