package tunnel

import (
	"bufio"
	"bytes"
	"errors"
	"fmt"
	"io"
	"io/ioutil"
	"net"
	"net/http"
	"strconv"
	"sync"
	"time"

	"github.com/koding/klient/Godeps/_workspace/src/github.com/cenkalti/backoff"
	"github.com/koding/klient/Godeps/_workspace/src/github.com/hashicorp/yamux"
	"github.com/koding/klient/Godeps/_workspace/src/github.com/koding/logging"
)

// Client is responsible for creating a control connection to a tunnel server,
// creating new tunnels and proxy them to tunnel server.
type Client struct {
	// underlying yamux session
	session *yamux.Session

	// config holds the ClientConfig
	config *ClientConfig

	// yamuxConfig is passed to new yamux.Session's
	yamuxConfig *yamux.Config
	log         logging.Logger

	mu          sync.Mutex // guards the following
	closed      bool       // if client calls Close() and quits
	startNotify chan bool  // notifies if client established a conn to server

	reqWg sync.WaitGroup

	// redialBackoff is used to reconnect in exponential backoff intervals
	redialBackoff backoff.BackOff
}

// ClientConfig defines the configuration for the Client
type ClientConfig struct {
	// Identifier is the secret token that needs to be passed to the server.
	// Required if FetchIdentifier is not set
	Identifier string

	// FetchIdentifier can be used to fetch identifier. Required if Identifier
	// is not set.
	FetchIdentifier func() (string, error)

	// ServerAddr defines the TCP address of the tunnel server to be connected. This is required.
	ServerAddr string

	// LocalAddr defines the TCP address of the local server. This is optional
	// if you want to specify a single TCP address. Otherwise the client will
	// always proxy to 127.0.0.1:incomingPort, where incomingPort is the
	// tunnelserver's public exposed Port.
	LocalAddr string

	// Debug enables debug mode, enable only if you want to debug the server.
	Debug bool

	// Log defines the logger. If nil a default logging.Logger is used.
	Log logging.Logger

	// YamuxConfig defines the config which passed to every new yamux.Session. If nil
	// yamux.DefaultConfig() is used.
	YamuxConfig *yamux.Config
}

// verify is used to verify the ClientConfig
func (c *ClientConfig) verify() error {
	if c.ServerAddr == "" {
		return errors.New("config.ServerAddr must be set")
	}

	if c.Identifier == "" && c.FetchIdentifier == nil {
		return errors.New("neither config.Identifier nor config.FetchIdentifier is set")
	}

	if c.YamuxConfig != nil {
		if err := yamux.VerifyConfig(c.YamuxConfig); err != nil {
			return err
		}
	}

	return nil
}

// NewClient creates a new tunnel that is established between the serverAddr
// and localAddr. It exits if it can't create a new control connection to the
// server. If localAddr is empty client will always try to proxy to a local
// port.
func NewClient(cfg *ClientConfig) (*Client, error) {
	yamuxConfig := yamux.DefaultConfig()
	if cfg.YamuxConfig != nil {
		yamuxConfig = cfg.YamuxConfig
	}

	log := newLogger("tunnel-client", cfg.Debug)
	if cfg.Log != nil {
		log = cfg.Log
	}

	if err := cfg.verify(); err != nil {
		return nil, err
	}

	forever := backoff.NewExponentialBackOff()
	forever.MaxElapsedTime = 365 * 24 * time.Hour // 1 year

	client := &Client{
		config:        cfg,
		log:           log,
		yamuxConfig:   yamuxConfig,
		redialBackoff: forever,
		startNotify:   make(chan bool, 1),
	}

	return client, nil
}

// Start starts the client and connects to the server with the identifier.
// client.FetchIdentifier() will be used if it's not nil. It's supports
// reconnecting with exponential backoff intervals when the connection to the
// server disconnects. Call client.Close() to shutdown the client completely. A
// successfull connection will cause StartNotify() to receive a value.
func (c *Client) Start() {
	id := func() (string, error) {
		if c.config.FetchIdentifier != nil {
			return c.config.FetchIdentifier()
		}

		return c.config.Identifier, nil
	}

	c.redialBackoff.Reset()
	for {
		time.Sleep(c.redialBackoff.NextBackOff())
		identifier, err := id()
		if err != nil {
			c.log.Critical("client fetch identifier err: %s", err.Error())
			continue
		}

		// mark it as not closed. Also empty the value inside the chan by
		// retrieving it (if any), so it doesn't block during connect, when the
		// client was closed and started again, and startNotify was never
		// listened to.
		c.mu.Lock()
		c.closed = false
		select {
		case <-c.startNotify:
		default:
		}
		c.mu.Unlock()

		if err := c.connect(identifier); err != nil {
			c.log.Debug("client connect err: %s", err.Error())
		}

		// exit if closed
		c.mu.Lock()
		if c.closed {
			c.mu.Unlock()
			return
		}
		c.mu.Unlock()
	}
}

// StartNotify returns a channel that receives a single value when the client
// established a successfull connection to the server.
func (c *Client) StartNotify() <-chan bool {
	return c.startNotify
}

// Close closes the client and shutdowns the connection to the tunnel server
func (c *Client) Close() error {
	if c.session == nil {
		return errors.New("session is not initialized")
	}

	if err := c.session.GoAway(); err != nil {
		return err
	}

	c.mu.Lock()
	c.closed = true
	c.mu.Unlock()

	c.reqWg.Wait() // wait until all connections are finished
	if err := c.session.Close(); err != nil {
		return err
	}

	return nil
}

func (c *Client) connect(identifier string) error {
	c.log.Debug("Trying to connect to '%s' with identifier '%s'", c.config.ServerAddr, identifier)
	conn, err := net.Dial("tcp", c.config.ServerAddr)
	if err != nil {
		return err
	}

	remoteAddr := fmt.Sprintf("http://%s%s", conn.RemoteAddr(), controlPath)
	c.log.Debug("CONNECT to '%s'", remoteAddr)
	req, err := http.NewRequest("CONNECT", remoteAddr, nil)
	if err != nil {
		return fmt.Errorf("CONNECT %s", err)
	}

	req.Header.Set(xKTunnelIdentifier, identifier)
	c.log.Debug("Writing request to TCP: %+v", req)
	if err := req.Write(conn); err != nil {
		return err
	}

	c.log.Debug("Reading response from TCP")
	resp, err := http.ReadResponse(bufio.NewReader(conn), req)
	if err != nil {
		return fmt.Errorf("read response %s", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 && resp.Status != connected {
		out, err := ioutil.ReadAll(resp.Body)
		if err != nil {
			return err
		}

		return fmt.Errorf("proxy server: %s. err: %s", resp.Status, string(out))
	}

	c.session, err = yamux.Client(conn, c.yamuxConfig)
	if err != nil {
		return err
	}

	var stream net.Conn

	openStream := func() error {
		// this is blocking until client opens a session to us
		stream, err = c.session.Open()
		return err
	}

	// if we don't receive anything from the server, we'll timeout
	select {
	case err := <-async(openStream):
		if err != nil {
			return err
		}
	case <-time.After(time.Second * 10):
		if stream != nil {
			stream.Close()
		}
		return errors.New("timeout opening session")
	}

	if _, err := stream.Write([]byte(ctHandshakeRequest)); err != nil {
		return err
	}

	buf := make([]byte, len(ctHandshakeResponse))
	if _, err := stream.Read(buf); err != nil {
		return err
	}

	if string(buf) != ctHandshakeResponse {
		return fmt.Errorf("handshake aborted. got: %s", string(buf))
	}

	ct := newControl(stream)
	c.log.Debug("client has started successfully.")
	c.redialBackoff.Reset() // we successfully connected, so we can reset the backoff

	c.mu.Lock()
	if c.startNotify != nil && !c.closed {
		c.log.Debug("sending ok to startNotify chan")
		select {
		case c.startNotify <- true:
		default:
			// reaching here means the client never read the signal via
			// StartNotify(). This is OK, we shouldn't except it the consumer
			// to read from this channel. It's optional, so we just drop the
			// signal.
		}
	}
	c.mu.Unlock()

	return c.listenControl(ct)
}

func (c *Client) listenControl(ct *control) error {
	for {
		var msg controlMsg
		err := ct.dec.Decode(&msg)
		if err != nil {
			c.reqWg.Wait() // wait until all requests are finished

			c.session.GoAway()
			c.session.Close()
			return err
		}

		c.log.Debug("Received control msg %+v", msg)

		switch msg.Action {
		case requestClientSession:
			c.log.Debug("Received request to open a session to server")
			go func() {
				if err := c.proxy(msg.LocalPort); err != nil {
					c.log.Error("Proxy err between remote and local: '%s'", err)
				}
			}()
		}
	}
}

func (c *Client) proxy(port int) error {
	c.log.Debug("Opening a new stream from server session")
	remote, err := c.session.Open()
	if err != nil {
		return err
	}
	defer remote.Close()

	if port == 0 {
		port = 80
	}

	localAddr := "127.0.0.1:" + strconv.Itoa(port)
	if c.config.LocalAddr != "" {
		localAddr = c.config.LocalAddr
	}

	c.log.Debug("Dialing local server %s", localAddr)
	local, err := net.Dial("tcp", localAddr)
	if err != nil {
		c.log.Debug("Dialing local server(%s) failed: %s", localAddr, err)

		// send a response instead of canceling it on the server side. at least
		// the public connection will know what's happening or not
		body := bytes.NewBufferString("no local server")
		resp := &http.Response{
			Status:        http.StatusText(http.StatusServiceUnavailable),
			StatusCode:    http.StatusServiceUnavailable,
			Proto:         "HTTP/1.1",
			ProtoMajor:    1,
			ProtoMinor:    1,
			Body:          ioutil.NopCloser(body),
			ContentLength: int64(body.Len()),
		}

		buf := new(bytes.Buffer)
		resp.Write(buf)
		if _, err := io.Copy(remote, buf); err != nil {
			c.log.Debug("copy in-mem response error: %s\n", err.Error())
		}
		return nil
	}

	c.log.Debug("Starting to proxy between remote and local server")
	c.reqWg.Add(1)
	c.join(local, remote)
	c.reqWg.Done()

	c.log.Debug("Proxing between remote and local server finished")
	return nil
}

func (c *Client) join(local, remote io.ReadWriteCloser) {
	var wg sync.WaitGroup
	wg.Add(2)

	transfer := func(side string, dst, src io.ReadWriteCloser) {
		_, err := io.Copy(dst, src)
		if err != nil {
			c.log.Debug("copy error: %s\n", err.Error())
		}

		if err := src.Close(); err != nil {
			c.log.Debug("%s: close error: %s\n", side, err.Error())
		}

		// not for yamux streams, but for client to local server connections
		if d, ok := dst.(*net.TCPConn); ok {
			if err := d.CloseWrite(); err != nil {
				c.log.Debug("%s: closeWrite error: %s\n", side, err.Error())
			}
		}

		wg.Done()
	}

	go transfer("remote to local", local, remote)
	go transfer("local to remote", remote, local)

	wg.Wait()
	return
}
