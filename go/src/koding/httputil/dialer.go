package httputil

import (
	"fmt"
	"net"
	"net/http"
	"runtime/debug"
	"sync"
	"time"

	"github.com/koding/logging"
)

var defaultLog = logging.NewCustom("dialer", false)

type Dialer struct {
	*net.Dialer

	mu    sync.Mutex // protects conns
	once  sync.Once
	conns map[*Conn]struct{}
	tick  *time.Ticker
	opts  *ClientConfig
}

func NewDialer(cfg *ClientConfig) *Dialer {
	return &Dialer{
		Dialer: &net.Dialer{
			Timeout:   cfg.DialTimeout,
			KeepAlive: cfg.KeepAlive,
		},
		opts: cfg,
	}
}

func (d *Dialer) Dial(network, addr string) (net.Conn, error) {
	if d.opts.TraceLeakedConn {
		return d.tracingDial(network, addr)
	}

	return d.Dialer.Dial(network, addr)
}

func (d *Dialer) init() {
	d.conns = make(map[*Conn]struct{})
	// never stopped as it is designed to live throughout whole process lifetime
	d.tick = time.NewTicker(d.tickInterval())
	go d.process()
}

func (d *Dialer) log() logging.Logger {
	if d.opts.Log != nil {
		return d.opts.Log
	}

	return defaultLog
}

func (d *Dialer) tickInterval() time.Duration {
	if d.opts.TickInterval != 0 {
		return d.opts.TickInterval
	}

	return 5 * time.Minute
}

func (d *Dialer) maxIdle() int {
	if d.opts.MaxIdleConns != 0 {
		return d.opts.MaxIdleConns
	}

	return http.DefaultMaxIdleConnsPerHost
}

func (d *Dialer) tracingDial(network, addr string) (net.Conn, error) {
	d.once.Do(d.init)

	conn, err := d.Dialer.Dial(network, addr)
	if err != nil {
		return nil, err
	}

	if d.opts.Director != nil {
		d.opts.Director(conn)
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

		var n int
		now := time.Now()

		for i, c := range conns {
			c := &c

			d.log().Debug("(%d/%d) active connection: %s", i+1, len(conns), c.ShortString())

			if dur := c.Since(now); dur > 10*time.Minute {
				n++

				if n > d.maxIdle() {
					d.log().Error("(%d/%d - %d) leaked connection (idle for %s): %s", i+1, len(conns), n, dur, c)
				} else {
					d.log().Info("(%d/%d) idle connection (active %s ago): %s", i+1, len(conns), dur, c)
				}
			}

			if dur := now.Sub(c.Connected); dur > 15*time.Minute {
				d.log().Info("(%d/%d) long-running connection (for %s): %s", i+1, len(conns), dur, c)
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
