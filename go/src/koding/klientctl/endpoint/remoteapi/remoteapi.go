package remoteapi

import (
	"net/url"
	"sync"

	"koding/klientctl/config"
	"koding/klientctl/endpoint"
	"koding/klientctl/endpoint/kloud"
	"koding/remoteapi"
	"koding/remoteapi/client"
	"koding/socialapi"
)

var DefaultClient = &Client{}

type Client struct {
	Kloud *kloud.Client

	once sync.Once // for c.init()
	c    *remoteapi.Client
}

func (c *Client) New(session *socialapi.Session) *client.Koding {
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

func New(session *socialapi.Session) *client.Koding { return DefaultClient.New(session) }
