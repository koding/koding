package remoteapi

import (
	"errors"
	"sync"
	"time"

	"koding/api"
	"koding/klientctl/config"
	"koding/klientctl/ctlcli"
	"koding/klientctl/endpoint"
	"koding/klientctl/endpoint/kloud"
	"koding/klientctl/endpoint/team"
	"koding/remoteapi"
	"koding/remoteapi/client"
)

// ErrNotFound is returned by Client methods when a requested
// resource was not found.
var ErrNotFound = errors.New("resource was not found")

// DefaultClient is a default remote.api client.
//
// It uses default kloud client as auth provider
// and kd cache for storing authentication tokens.
var DefaultClient = &Client{}

// DefaultTimeout defines max remote.api request time,
// after which the request is cancelled.
var DefaultTimeout = 30 * time.Second

// Client is a wrapper for remote.api client that takes
// care of authorization and caching.
type Client struct {
	Kloud  *kloud.Client  // if nil, kloud.DefaultClient is used
	Team   *team.Client   // if nil, team.DefaultClient is used
	Client *client.Koding // if nil, new client is created (with kloud as auth provider)

	once sync.Once // for c.init()
	api  *remoteapi.Client
	c    *client.Koding
}

// New creates new remoteapi client for the given user.
func (c *Client) New(user *api.User) *client.Koding {
	c.init()

	return c.api.New(user)
}

// Close flushes all underlying caches and closes all clients.
func (c *Client) Close() error {
	return nil
}

func (c *Client) init() {
	c.once.Do(c.initClient)
}

func (c *Client) initClient() {
	if c.Client == nil {
		c.api = &remoteapi.Client{
			Transport: endpoint.Transport(c.kloud()),
			Endpoint:  config.Konfig.Endpoints.Remote().Public.URL,
		}
		c.c = c.api.New(&api.User{
			Username: c.kloud().Username(),
			Team:     c.team().Used().Name,
		})
	}

	// Ensure DefaultClient is closed on exit.
	if c == DefaultClient {
		ctlcli.CloseOnExit(c)
	}
}

func (c *Client) kloud() *kloud.Client {
	if c.Kloud != nil {
		return c.Kloud
	}
	return kloud.DefaultClient
}

func (c *Client) team() *team.Client {
	if c.Team != nil {
		return c.Team
	}
	return team.DefaultClient
}

func (c *Client) client() *client.Koding {
	if c.Client != nil {
		return c.Client
	}
	return c.c
}

func (c *Client) timeout() time.Duration {
	if c.api != nil {
		return c.api.Timeout()
	}
	return DefaultTimeout
}
