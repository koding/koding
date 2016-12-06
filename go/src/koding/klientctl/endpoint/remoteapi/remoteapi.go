package remoteapi

import (
	"net/url"
	"sync"

	"koding/api"
	"koding/klientctl/config"
	"koding/klientctl/endpoint"
	"koding/klientctl/endpoint/kloud"
	"koding/remoteapi"
	"koding/remoteapi/client"
)

var DefaultClient = &Client{}

type Client struct {
	Kloud *kloud.Client

	once sync.Once // for c.init()
	c    *remoteapi.Client
}

func (c *Client) New(session *api.Session) *client.Koding {
	c.init()

	return c.c.New(session)
}

func (c *Client) init() {
	c.once.Do(c.initClient)
}

func (c *Client) initClient() {
	c.c = &remoteapi.Client{
		Transport: endpoint.Transport(c.kloud()),
	}

	if u, err := url.Parse(config.Konfig.RemoteURL); err == nil {
		c.c.Endpoint = u
	}
}

func (c *Client) kloud() *kloud.Client {
	if c.Kloud != nil {
		return c.Kloud
	}
	return kloud.DefaultClient
}

func New(session *api.Session) *client.Koding { return DefaultClient.New(session) }
