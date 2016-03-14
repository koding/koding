package e2etest

import (
	"bufio"
	"fmt"
	"io"
	"koding/kites/tunnelproxy"
	"log"
	"net"
	"strconv"
	"sync"
	"time"
)

var tcpTimeout = 10 * time.Second

func newEchoService() (net.Listener, error) {
	l, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		return nil, err
	}

	go func() {
		conn, err := l.Accept()
		if err != nil {
			Test.Log.Warning("accept on %s stopped", l.Addr())
			return
		}

		Test.Log.Debug("[ECHO] accepted %q on %q", conn.RemoteAddr(), l.Addr())

		go io.Copy(conn, conn)
	}()

	return l, nil
}

type ServiceRecorder struct {
	ch       chan map[string]*tunnelproxy.Tunnel
	recorded map[string]*tunnelproxy.Tunnel
	mu       sync.Mutex
}

func newServiceRecorder() *ServiceRecorder {
	return &ServiceRecorder{
		ch:       make(chan map[string]*tunnelproxy.Tunnel),
		recorded: make(map[string]*tunnelproxy.Tunnel),
	}
}

func (rec *ServiceRecorder) Wait(services ...string) error {
	timeout := time.After(5 * time.Second)
	for {
		select {
		case <-timeout:
			return fmt.Errorf("timed out waiting for services: %v", services)
		default:
			var ok bool
			var tun *tunnelproxy.Tunnel
			var err error
			rec.mu.Lock()
			for _, name := range services {
				tun, ok = rec.recorded[name]
				if !ok {
					break
				}

				if err = tun.Err(); err != nil {
					err = fmt.Errorf("registering %q service failed: %s", name, err)
					break
				}
			}
			rec.mu.Unlock()

			if err != nil {
				return err
			}

			if ok {
				return nil
			}

			time.Sleep(50 * time.Millisecond)
		}
	}
}

func (rec *ServiceRecorder) Clear() {
	rec.mu.Lock()
	rec.recorded = make(map[string]*tunnelproxy.Tunnel)
	rec.mu.Unlock()
}

func (rec *ServiceRecorder) Services() map[string]*tunnelproxy.Tunnel {
	rec.mu.Lock()
	defer rec.mu.Unlock()

	m := make(map[string]*tunnelproxy.Tunnel, len(rec.recorded))

	for k, v := range rec.recorded {
		m[k] = v
	}

	return m
}

func (rec *ServiceRecorder) Record(resp *tunnelproxy.RegisterServicesResult) {
	rec.mu.Lock()
	for name, srv := range resp.Services {
		rec.recorded[name] = srv
	}
	rec.mu.Unlock()
}

type tcpClient struct {
	conn    net.Conn
	scanner *bufio.Scanner
	in      chan string
	out     chan string
}

func (c *tcpClient) loop() {
	for out := range c.out {
		if _, err := fmt.Fprintln(c.conn, out); err != nil {
			log.Printf("[tunnelclient] error writing %q to %q: %s", out, c.conn.RemoteAddr(), err)
			return
		}

		if !c.scanner.Scan() {
			log.Printf("[tunnelclient] error reading from %q: %v", c.conn.RemoteAddr(), c.scanner.Err())
			return
		}

		c.in <- c.scanner.Text()
	}
}

func (c *tcpClient) Close() error {
	close(c.out)
	return c.conn.Close()
}

func dialTCP(port int) (*tcpClient, error) {
	addr := net.JoinHostPort("127.0.0.1", strconv.Itoa(port))
	conn, err := net.DialTimeout("tcp", addr, tcpTimeout)
	if err != nil {
		return nil, err
	}

	c := &tcpClient{
		conn:    conn,
		scanner: bufio.NewScanner(conn),
		in:      make(chan string, 1),
		out:     make(chan string, 1),
	}

	go c.loop()

	return c, nil
}
