package team

import (
	"errors"
	"sync"

	"koding/klientctl/ctlcli"
	"koding/klientctl/endpoint/kloud"
)

var DefaultClient = &Client{}

type Team struct {
	Name string `json:"name"`
}

func (t *Team) Valid() error {
	if t.Name == "" {
		return errors.New("invalid empty team name")
	}
	return nil
}

type Client struct {
	Kloud *kloud.Client

	once sync.Once // for c.init()
	used Team
}

func (c *Client) Use(team *Team) {
	c.init()

	c.used = *team
}

func (c *Client) Used() *Team {
	c.init()

	return &c.used
}

func (c *Client) Close() (err error) {
	if c.used.Valid() == nil {
		err = c.kloud().Cache().SetValue("team.used", &c.used)
	}

	return err
}

func (c *Client) init() {
	c.once.Do(c.readCache)
}

func (c *Client) readCache() {
	// Ignoring read error, if it's non-nil then empty cache is going to
	// be used instead.
	_ = c.kloud().Cache().GetValue("team.used", &c.used)

	// Flush cache on exit.
	ctlcli.CloseOnExit(c)
}

func (c *Client) kloud() *kloud.Client {
	if c.Kloud != nil {
		return c.Kloud
	}
	return kloud.DefaultClient
}

func Use(team *Team) { DefaultClient.Use(team) }
func Used() *Team    { return DefaultClient.Used() }
