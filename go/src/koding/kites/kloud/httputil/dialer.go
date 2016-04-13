package httputil

import (
	"fmt"
	"koding/kites/common"
	"net"
	"runtime/debug"
	"sync"
	"time"

	"github.com/koding/logging"
)

var defaultLog = common.NewLogger("dialer", false)

type Dialer struct {
	*net.Dialer
	Log   logging.Logger
	Debug bool

	mu    sync.Mutex // protects conns
	once  sync.Once
	conns map[*Conn]struct{}
	tick  *time.Ticker
}

func NewDialer(cfg *ClientConfig) *Dialer {
	return &Dialer{
		Dialer: &net.Dialer{
			Timeout:   cfg.DialTimeout,
			KeepAlive: cfg.KeepAlive,
		},
		Log:   cfg.Log,
		Debug: cfg.DebugTCP,
	}
}

func (d *Dialer) Dial(network, addr string) (net.Conn, error) {
	if !d.Debug {
		return d.Dialer.Dial(network, addr)
	}

	return d.dial(network, addr)
}

func (d *Dialer) init() {
	d.conns = make(map[*Conn]struct{})
	d.tick = time.NewTicker(5 * time.Minute)
	go d.process()
}

func (d *Dialer) log() logging.Logger {
	if d.Log != nil {
		return d.Log
	}

	return defaultLog
}

func (d *Dialer) dial(network, addr string) (net.Conn, error) {
	d.once.Do(d.init)

	conn, err := d.Dialer.Dial(network, addr)
	if err != nil {
		return nil, err
	}

	c := &Conn{
		Connected:  time.Now(),
		Stacktrace: string(debug.Stack()),
		Conn:       conn,
		network:    network,
		addr:       addr,
	}

	c.close = func() {
		d.mu.Lock()
		delete(d.conns, c)
		d.mu.Unlock()

		d.log().Debug("connection closed: %s", c.ShortString())
	}

	d.mu.Lock()
	d.conns[c] = struct{}{}
	d.mu.Unlock()

	return c, nil
}

func (d *Dialer) process() {
	d.log().Debug("starting processing goroutine (%p)", d)

	for range d.tick.C {
		d.mu.Lock()
		conns := make([]Conn, 0, len(d.conns)) // stores copies of all Conns
		for c := range d.conns {
			c.mu.Lock()
			conns = append(conns, *c) // shallow copy of Conn
			c.mu.Unlock()
		}
		d.mu.Unlock()

		now := time.Now()

		for i, c := range conns {
			c := &c

			d.log().Debug("(%d/%d) active connection: %s", i+1, len(conns), c.ShortString())

			if dur := c.Since(now); dur > 10*time.Minute {
				// To be accurate each HTTP client can hold multiple idle
				// conections per host (2 by default); if number of idle
				// connections per host greatly exceeds that number then
				// it may be a leak.
				d.log().Error("(%d/%d) possible leak, idle connection was active %s ago: %s", i+1, len(conns), dur, c)
			}

			if dur := now.Sub(c.Connected); dur > 15*time.Minute {
				d.log().Warning("(%d/%d) long-running connection %s: %s", i+1, len(conns), dur, c)
			}
		}
	}
}

type Conn struct {
	Connected    time.Time
	LastRead     time.Time
	LastWrite    time.Time
	BytesRead    int64
	BytesWritten int64
	Stacktrace   string

	network string
	addr    string
	mu      sync.Mutex // protects Last{Read,Write} and Bytes{Read,Written}
	close   func()
	net.Conn
}

func (c *Conn) Since(now time.Time) time.Duration {
	if now.IsZero() {
		now = time.Now()
	}

	last := c.LastRead
	if c.LastWrite.After(last) {
		last = c.LastWrite
	}

	return now.Sub(last)
}

func (c *Conn) ShortString() string {
	return fmt.Sprintf("%s->%s (%q, %q): BytesRead=%d, BytesWritten=%d, Duration=%s",
		c.Conn.LocalAddr(), c.Conn.RemoteAddr(), c.network, c.addr, c.BytesRead,
		c.BytesWritten, c.Since(time.Now()))
}

func (c *Conn) String() string {
	return fmt.Sprintf("%s->%s (%q, %q): Connected=%s, BytesRead=%d, LastRead=%s, BytesWritten=%d, LastWrite=%s, Stacktrace=%s",
		c.Conn.LocalAddr(), c.Conn.RemoteAddr(), c.network, c.addr, c.Connected, c.BytesRead, c.LastRead, c.BytesWritten,
		c.LastWrite, c.Stacktrace)
}

func (c *Conn) Read(p []byte) (int, error) {
	n, err := c.Conn.Read(p)

	c.mu.Lock()
	c.LastRead = time.Now()
	c.BytesRead += int64(n)
	c.mu.Unlock()

	return n, err
}

func (c *Conn) Write(p []byte) (int, error) {
	n, err := c.Conn.Write(p)

	c.mu.Lock()
	c.LastWrite = time.Now()
	c.BytesWritten += int64(n)
	c.mu.Unlock()

	return n, err
}

func (c *Conn) Close() error {
	c.close()

	return c.Conn.Close()
}
