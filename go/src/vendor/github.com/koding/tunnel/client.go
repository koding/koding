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
	"sync/atomic"
	"time"

	"github.com/hashicorp/yamux"
	"github.com/koding/logging"
)

//go:generate stringer -type ClientState

// ErrRedialAborted is emitted on ClientClosed event, when backoff policy
// used by a client decided no more reconnection attempts must be made.
var ErrRedialAborted = errors.New("unable to restore the connection, aborting")

// ClientState represents client connection state to tunnel server.
type ClientState uint32

const (
	ClientUnknown ClientState = iota
	ClientStarted
	ClientConnecting
	ClientConnected
	ClientDisconnected
	ClientClosed // keep it always last
)

// ClientStateChange represents single client state transition.
type ClientStateChange struct {
	Previous ClientState
	Current  ClientState
	Error    error
}

// Strings implements the fmt.Stringer interface.
func (cs *ClientStateChange) String() string {
	if cs.Error != nil {
		return fmt.Sprintf("%s->%s (%s)", cs.Previous, cs.Current, cs.Error)
	}
	return fmt.Sprintf("%s->%s", cs.Previous, cs.Current)
}

// Backoff defines behavior of staggering reconnection retries.
type Backoff interface {
	// Next returns the duration to sleep before retrying reconnections.
	// If the returned value is negative, the retry is aborted.
	NextBackOff() time.Duration

	// Reset is used to signal a reconnection was successful and next
	// call to Next should return desired time duration for 1st reconnection
	// attempt.
	Reset()
}

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

	// startNotify is a chanel user can get to be notified when client is
	// connected to the server. The preferred way of doing this however,
	// would be using StateChanges in ClientConfig where user can provide
	// his own channel.
	startNotify chan bool
	// closed is a flag set when client calls Close() and quits.
	closed bool
	// closedMu guards both closed flag and startNotify channel. Since library
	// owns the channel it's cleared when trying to reconnect.
	closedMu sync.RWMutex

	reqWg  sync.WaitGroup
	ctrlWg sync.WaitGroup

	// redialBackoff is used to reconnect in exponential backoff intervals
	redialBackoff Backoff

	state ClientState
}

// ClientConfig defines the configuration for the Client
type ClientConfig struct {
	// Identifier is the secret token that needs to be passed to the server.
	// Required if FetchIdentifier is not set.
	Identifier string

	// FetchIdentifier can be used to fetch identifier. Required if Identifier
	// is not set.
	FetchIdentifier func() (string, error)

	// ServerAddr defines the TCP address of the tunnel server to be connected.
	// Required if FetchServerAddr is not set.
	ServerAddr string

	// FetchServerAddr can be used to fetch tunnel server address.
	// Required if ServerAddress is not set.
	FetchServerAddr func() (string, error)

	// LocalAddr defines the TCP address of the local server. This is optional
	// if you want to specify a single TCP address. Otherwise the client will
	// always proxy to 127.0.0.1:incomingPort, where incomingPort is the
	// tunnelserver's public exposed Port.
	LocalAddr string

	// FetchLocalAddr is used for looking up TCP address of the server,
	// which an incoming connection should be proxied to.
	//
	// If port-based routing is used, this field is required for tunneling to
	// function properly. Otherwise you'll be forwarding traffic to random
	// ports and this is usually not desired.
	//
	// If IP-based routing is used this field may be nil, in that case
	// "127.0.0.1:port" will be used instead.
	FetchLocalAddr func(port int) (string, error)

	// Debug enables debug mode, enable only if you want to debug the server.
	Debug bool

	// Log defines the logger. If nil a default logging.Logger is used.
	Log logging.Logger

	// Dial provides custom transport layer for client server communication.
	//
	// If nil, default implementation is to return net.Dial("tcp", address).
	//
	// It can be used for connection monitoring, setting different timeouts or
	// securing the connection.
	Dial func(network, address string) (net.Conn, error)

	// StateChanges receives state transition details each time client
	// connection state changes. The channel is expected to be sufficiently
	// buffered to keep up with event pace.
	//
	// If nil, no information about state transitions are dispatched
	// by the library.
	StateChanges chan<- *ClientStateChange

	// Backoff is used to control behavior of staggering reconnection loop.
	//
	// If nil, default backoff policy is used which makes a client to never
	// give up on reconnection.
	//
	// If custom backoff is used, client will emit ErrRedialAborted set
	// with ClientClosed event when no more reconnection atttemps should
	// be made.
	Backoff Backoff

	// YamuxConfig defines the config which passed to every new yamux.Session. If nil
	// yamux.DefaultConfig() is used.
	YamuxConfig *yamux.Config
}

// verify is used to verify the ClientConfig
func (c *ClientConfig) verify() error {
	if c.ServerAddr == "" && c.FetchServerAddr == nil {
		return errors.New("neither ServerAddr nor FetchServerAddr is set")
	}

	if c.Identifier == "" && c.FetchIdentifier == nil {
		return errors.New("neither Identifier nor FetchIdentifier is set")
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

	client := &Client{
		config:        cfg,
		log:           log,
		yamuxConfig:   yamuxConfig,
		redialBackoff: cfg.Backoff,
		startNotify:   make(chan bool, 1),
	}

	if client.redialBackoff == nil {
		client.redialBackoff = newForeverBackoff()
	}

	return client, nil
}

// Start starts the client and connects to the server with the identifier.
// client.FetchIdentifier() will be used if it's not nil. It's supports
// reconnecting with exponential backoff intervals when the connection to the
// server disconnects. Call client.Close() to shutdown the client completely. A
// successful connection will cause StartNotify() to receive a value.
func (c *Client) Start() {
	fetchIdent := func() (string, error) {
		if c.config.FetchIdentifier != nil {
			return c.config.FetchIdentifier()
		}

		return c.config.Identifier, nil
	}

	fetchServerAddr := func() (string, error) {
		if c.config.FetchServerAddr != nil {
			return c.config.FetchServerAddr()
		}

		return c.config.ServerAddr, nil
	}

	c.changeState(ClientStarted, nil)

	c.redialBackoff.Reset()
	var lastErr error
	for {
		prev := c.changeState(ClientConnecting, lastErr)

		if c.isRetry(prev) {
			dur := c.redialBackoff.NextBackOff()
			if dur < 0 {
				c.setClosed(true)
				c.changeState(ClientClosed, ErrRedialAborted)
				return
			}

			time.Sleep(dur)

			// exit if closed
			if c.isClosed() {
				c.changeState(ClientClosed, lastErr)
				return
			}
		}

		identifier, err := fetchIdent()
		if err != nil {
			lastErr = err
			c.log.Critical("client fetch identifier error: %s", err)
			continue
		}

		serverAddr, err := fetchServerAddr()
		if err != nil {
			lastErr = err
			c.log.Critical("client fetch server address error: %s", err)
			continue
		}

		c.setClosed(false)

		if err := c.connect(identifier, serverAddr); err != nil {
			lastErr = err
			c.log.Debug("client connect error: %s", err)
		}

		// exit if closed
		if c.isClosed() {
			c.changeState(ClientClosed, lastErr)
			return
		}
	}
}

// Close closes the client and shutdowns the connection to the tunnel server
func (c *Client) Close() error {
	defer c.setClosed(true)

	if c.session == nil {
		return errors.New("session is not initialized")
	}

	// wait until all connections are finished
	waitCh := make(chan struct{})
	go func() {
		if err := c.session.GoAway(); err != nil {
			c.log.Debug("Session go away failed: %s", err)
		}

		c.reqWg.Wait()
		close(waitCh)
	}()
	select {
	case <-waitCh:
		// ok
	case <-time.After(time.Second * 10):
		c.log.Info("Timeout waiting for connections to finish")
	}

	if err := c.session.Close(); err != nil {
		return err
	}

	return nil
}

// isClosed securely checks if client is marked as closed.
func (c *Client) isClosed() bool {
	c.closedMu.RLock()
	defer c.closedMu.RUnlock()
	return c.closed
}

// setClosed securely marks client as closed (or not closed). If not closed
// also empty the value inside the startNotify channel by retrieving it (if any),
// so it doesn't block during connect, when the client was closed and started again,
// and startNotify was never listened to.
func (c *Client) setClosed(closed bool) {
	c.closedMu.Lock()
	defer c.closedMu.Unlock()
	c.closed = closed

	if !closed {
		// clear channel
		select {
		case <-c.startNotify:
		default:
		}
	}
}

// startNotifyIfNeeded sends ok to startNotify channel if it's listened to.
// This function is called by connect when connection was successful.
func (c *Client) startNotifyIfNeeded() {
	c.closedMu.RLock()
	if !c.closed {
		c.log.Debug("sending ok to startNotify chan")
		select {
		case c.startNotify <- true:
		default:
			// reaching here means the client never read the signal via
			// StartNotify(). This is OK, we shouldn't except it the consumer
			// to read from this channel. It's optional, so we just drop the
			// signal.
			c.log.Debug("startNotify message was dropped")
		}
	}
	c.closedMu.RUnlock()
}

// StartNotify returns a channel that receives a single value when the client
// established a successful connection to the server.
func (c *Client) StartNotify() <-chan bool {
	return c.startNotify
}

func (c *Client) changeState(state ClientState, err error) (prev ClientState) {
	prev = ClientState(atomic.LoadUint32((*uint32)(&c.state)))

	if c.config.StateChanges != nil {
		change := &ClientStateChange{
			Previous: ClientState(prev),
			Current:  state,
			Error:    err,
		}

		select {
		case c.config.StateChanges <- change:
		default:
		}
	}

	atomic.CompareAndSwapUint32((*uint32)(&c.state), uint32(prev), uint32(state))

	return prev
}

func (c *Client) isRetry(state ClientState) bool {
	return state != ClientStarted && state != ClientClosed
}

func (c *Client) connect(identifier, serverAddr string) error {
	c.log.Debug("Trying to connect to %q with identifier %q", serverAddr, identifier)

	conn, err := c.dial(serverAddr)
	if err != nil {
		return err
	}

	remoteUrl := controlUrl(conn)
	c.log.Debug("CONNECT to %q", remoteUrl)
	req, err := http.NewRequest("CONNECT", remoteUrl, nil)
	if err != nil {
		return fmt.Errorf("error creating request to %s: %s", remoteUrl, err)
	}

	req.Header.Set(xKTunnelIdentifier, identifier)

	c.log.Debug("Writing request to TCP: %+v", req)

	if err := req.Write(conn); err != nil {
		return fmt.Errorf("writing CONNECT request to %s failed: %s", req.URL, err)
	}

	c.log.Debug("Reading response from TCP")

	resp, err := http.ReadResponse(bufio.NewReader(conn), req)
	if err != nil {
		return fmt.Errorf("reading CONNECT response from %s failed: %s", req.URL, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 && resp.Status != connected {
		out, err := ioutil.ReadAll(resp.Body)
		if err != nil {
			return fmt.Errorf("tunnel server error: status=%d, error=%s", resp.StatusCode, err)
		}

		return fmt.Errorf("tunnel server error: status=%d, body=%s", resp.StatusCode, string(out))
	}

	c.ctrlWg.Wait() // wait until previous listenControl observes disconnection

	c.session, err = yamux.Client(conn, c.yamuxConfig)
	if err != nil {
		return fmt.Errorf("session initialization failed: %s", err)
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
			return fmt.Errorf("waiting for session to open failed: %s", err)
		}
	case <-time.After(time.Second * 10):
		if stream != nil {
			stream.Close()
		}
		return errors.New("timeout opening session")
	}

	if _, err := stream.Write([]byte(ctHandshakeRequest)); err != nil {
		return fmt.Errorf("writing handshake request failed: %s", err)
	}

	buf := make([]byte, len(ctHandshakeResponse))
	if _, err := stream.Read(buf); err != nil {
		return fmt.Errorf("reading handshake response failed: %s", err)
	}

	if string(buf) != ctHandshakeResponse {
		return fmt.Errorf("invalid handshake response, received: %s", string(buf))
	}

	ct := newControl(stream)
	c.log.Debug("client has started successfully.")
	c.redialBackoff.Reset() // we successfully connected, so we can reset the backoff

	c.startNotifyIfNeeded()

	return c.listenControl(ct)
}

func (c *Client) dial(serverAddr string) (net.Conn, error) {
	if c.config.Dial != nil {
		return c.config.Dial("tcp", serverAddr)
	}

	return net.Dial("tcp", serverAddr)
}

func (c *Client) listenControl(ct *control) error {
	c.ctrlWg.Add(1)
	defer c.ctrlWg.Done()

	c.changeState(ClientConnected, nil)

	for {
		var msg controlMsg
		err := ct.dec.Decode(&msg)
		if err != nil {
			c.reqWg.Wait() // wait until all requests are finished
			c.session.GoAway()
			c.session.Close()
			c.changeState(ClientDisconnected, err)

			return fmt.Errorf("failure decoding control message: %s", err)
		}

		c.log.Debug("Received control msg %+v", msg)

		switch msg.Action {
		case requestClientSession:
			switch msg.Protocol {
			case tcpTransport:
				c.log.Debug("Received request to open a TCP session to server")

				go func() {
					if err := c.proxyTCP(msg.LocalPort); err != nil {
						c.log.Error("proxying between remote and local failed: %s", err)
					}
				}()

			case wsTransport, httpTransport:
				c.log.Debug("Received request to open a HTTP session to server")

				go func() {
					if err := c.proxyHTTP(msg.LocalPort); err != nil {
						c.log.Error("Proxy err between remote and local: '%s'", err)
					}
				}()
			}
		}
	}
}

func (c *Client) proxyTCP(port int) error {
	c.log.Debug("Opening a new stream from server session")

	remote, err := c.session.Open()
	if err != nil {
		return err
	}
	defer remote.Close()

	localAddr := fmt.Sprintf("127.0.0.1:%d", port)
	if c.config.FetchLocalAddr != nil {
		localAddr, err = c.config.FetchLocalAddr(port)
		if err != nil {
			return fmt.Errorf("failed to fetch LocalAddr for port %d: %s", port, err)
		}
	}

	c.log.Debug("Dialing local server: %s", localAddr)

	local, err := net.DialTimeout("tcp", localAddr, defaultTimeout)
	if err != nil {
		c.log.Error("dialing local server %s failed: %s", localAddr, err)
		return err
	}

	c.join(local, remote)

	return nil
}

func (c *Client) proxyHTTP(port int) error {
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

	c.log.Debug("Dialing local server: %s", localAddr)
	local, err := net.DialTimeout("tcp", localAddr, defaultTimeout)
	if err != nil {
		c.log.Error("dialing local server %s failed: %s", localAddr, err)

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
			c.log.Debug("copy in-mem response error: %s", err)
		}
		return nil
	}

	c.reqWg.Add(1)
	c.join(local, remote)
	c.reqWg.Done()

	return nil
}

func (c *Client) join(local, remote net.Conn) {
	var wg sync.WaitGroup
	wg.Add(2)

	transfer := func(side string, dst, src net.Conn) {
		c.log.Debug("proxing %s -> %s", src.RemoteAddr(), dst.RemoteAddr())

		n, err := io.Copy(dst, src)
		if err != nil {
			c.log.Error("%s: copy error: %s", side, err)
		}

		if err := src.Close(); err != nil {
			c.log.Debug("%s: close error: %s", side, err)
		}

		// not for yamux streams, but for client to local server connections
		if d, ok := dst.(*net.TCPConn); ok {
			if err := d.CloseWrite(); err != nil {
				c.log.Debug("%s: closeWrite error: %s", side, err)
			}
		}

		wg.Done()
		c.log.Debug("done proxing %s -> %s: %d bytes", src.RemoteAddr(), dst.RemoteAddr(), n)
	}

	go transfer("remote to local", local, remote)
	go transfer("local to remote", remote, local)

	wg.Wait()
}
