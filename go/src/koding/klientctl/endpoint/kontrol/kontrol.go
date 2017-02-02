package kontrol

import (
	cfg "koding/kites/config"
	"koding/klientctl/config"
	"koding/klientctl/endpoint/kloud"
)

// RegisterRequest represents a request payload
// for one of kontrol's method - registerMachine.
type RegisterRequest struct {
	AuthType string // authentication type - here "token"
	Token    string // temporary token
}

// DefaultClient represents a Client, which default
// behaviour is to use default kloud client and
// default configuration read from configstore.
var DefaultClient = &Client{}

// Client is a convenience wrapper for kite.Client
// that is connected to Kontrol.
//
// The wrapper uses kite configuration which is
// already built by kloud's client and uses
// kontrol url read from configstore.
type Client struct {
	Kloud  *kloud.Client
	Konfig *cfg.Konfig

	t kloud.Transport
}

// Call invokes the given method with the given request payload.
//
// If call succeeds, result is unmarshaled to the resp value.
func (c *Client) Call(method string, req, resp interface{}) error {
	t, err := c.transport()
	if err != nil {
		return err
	}

	return t.Call(method, req, resp)
}

func (c *Client) kloud() *kloud.Client {
	if c.Kloud != nil {
		return c.Kloud
	}
	return kloud.DefaultClient
}

func (c *Client) konfig() *cfg.Konfig {
	if c.Konfig != nil {
		return c.Konfig
	}
	return config.Konfig
}

func (c *Client) transport() (kloud.Transport, error) {
	if c.t != nil {
		return c.t, nil
	}

	t, err := c.kloud().Transport.Connect(c.konfig().Endpoints.Kontrol().Public.String())
	if err != nil {
		return nil, err
	}

	c.t = t

	return c.t, nil
}

// Call invokes the given method with the given request payload on the DefaultClient.
//
// If call succeeds, result is unmarshaled to the resp value.
func Call(method string, req, resp interface{}) error { return DefaultClient.Call(method, req, resp) }
