package remoteapi

import (
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

func (c *Client) New(user *api.User) *client.Koding {
	c.init()

	return c.c.New(user)
}

func (c *Client) init() {
	c.once.Do(c.initClient)
}

func (c *Client) initClient() {
	c.c = &remoteapi.Client{
		Transport: endpoint.Transport(c.kloud()),
		Endpoint:  config.Konfig.Endpoints.Remote().Public.URL,
	}
}

func (c *Client) kloud() *kloud.Client {
	if c.Kloud != nil {
		return c.Kloud
	}
	return kloud.DefaultClient
}

func New(user *api.User) *client.Koding { return DefaultClient.New(user) }
