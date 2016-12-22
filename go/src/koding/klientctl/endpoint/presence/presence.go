package presence

import (
	"sync"

	"koding/api/presence"
	"koding/klientctl/config"
	"koding/klientctl/endpoint/kloud"
	"koding/klientctl/endpoint/team"
)

var DefaultClient = &Client{}

type Client struct {
	Kloud *kloud.Client
	Team  *team.Client

	once sync.Once
	c    *presence.Client
}

func (c *Client) Ping(team string) error {
	if team == "" {
		team = c.team().Used().Name
	}

	return c.c.Ping(c.kloud().Username(), team)
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

func (c *Client) init() {
	c.once.Do(c.initClient)
}

func (c *Client) initClient() {
	c.c = &presence.Client{
		Endpoint: config.Konfig.Endpoints.Social().Public.WithPath("presence").URL,
	}
}

func Ping(team string) error { return DefaultClient.Ping(team) }
