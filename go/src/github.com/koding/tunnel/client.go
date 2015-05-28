package tunnel

import (
	"bufio"
	"errors"
	"fmt"
	"io"
	"io/ioutil"
	"net"
	"net/http"
	"os"
	"time"

	"github.com/cenkalti/backoff"
	"github.com/hashicorp/yamux"
	"github.com/koding/logging"
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
	}

	return client, nil
}

// Start starts the client and connects to the server with the identifier.
// client.FetchIdentifier() will be used if it's not nil. It's supports
// reconnecting with exponential backoff intervals when the connection to the
// server disconnects.
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

		if err := c.connect(identifier); err != nil {
			c.log.Critical("client connect err: %s", err.Error())
		}
	}
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
	return c.listenControl(ct)
}

func (c *Client) listenControl(ct *control) error {
	for {
		var msg controlMsg
		err := ct.dec.Decode(&msg)
		if err != nil {
			c.session.GoAway()
			c.session.Close()
			return fmt.Errorf("decode err: '%s'", err)
		}

		c.log.Debug("controlMsg: %+v", msg)

		switch msg.Action {
		case requestClientSession:
			go func() {
				if err := c.proxy(msg.LocalPort); err != nil {
					fmt.Fprintf(os.Stderr, "proxy err: '%s'\n", err)
				}
			}()
		}
	}
}

func (c *Client) proxy(port string) error {
	conn, err := c.session.Open()
	if err != nil {
		return err
	}

	if port == "0" {
		port = "80"
	}

	localAddr := "127.0.0.1:" + port
	if c.config.LocalAddr != "" {
		localAddr = c.config.LocalAddr
	}

	local, err := newLocalDial(localAddr)
	if err != nil {
		return err
	}

	go func() {
		<-join(local, conn)
		conn.Close()
	}()

	return nil
}

func newLocalDial(addr string) (net.Conn, error) {
	c, err := net.Dial("tcp", addr)
	if err != nil {
		return nil, err
	}

	c.SetDeadline(time.Time{})
	return c, nil
}

func join(local, remote io.ReadWriteCloser) chan error {
	errc := make(chan error, 2)

	copy := func(dst io.Writer, src io.Reader) {
		_, err := io.Copy(dst, src)
		errc <- err
	}

	go copy(local, remote)
	go copy(remote, local)

	return errc
}
