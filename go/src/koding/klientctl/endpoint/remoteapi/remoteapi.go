package remoteapi

import (
	"sync"

	"koding/api"
	"koding/klientctl/config"
	"koding/klientctl/endpoint"
	"koding/klientctl/endpoint/kloud"
	"koding/klientctl/endpoint/team"
	"koding/remoteapi"
	"koding/remoteapi/client"
)

var DefaultClient = &Client{}

type Client struct {
	Kloud *kloud.Client
	Team  *team.Client

	once   sync.Once // for c.init()
	api    *remoteapi.Client
	client *client.Koding
}

func (c *Client) New(user *api.User) *client.Koding {
	c.init()

	return c.api.New(user)
}

func (c *Client) init() {
	c.once.Do(c.initClient)
}

func (c *Client) initClient() {
	c.api = &remoteapi.Client{
		Transport: endpoint.Transport(c.kloud()),
		Endpoint:  config.Konfig.Endpoints.Remote().Public.URL,
	}
	c.client = c.api.New(&api.User{
		Username: c.kloud().Username(),
		Team:     c.team().Used().Name,
	})
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
