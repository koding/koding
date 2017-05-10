package team

import (
	"errors"
	"sync"

	"koding/kites/kloud/stack"
	"koding/kites/kloud/team"
	"koding/klientctl/ctlcli"
	"koding/klientctl/endpoint/kloud"
)

var DefaultClient = &Client{}

func init() {
	ctlcli.CloseOnExit(DefaultClient)
}

// ListOptions are options available for `team list` command.
type ListOptions struct {
	Slug string // Limit to a specific team with a given name.
}

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

// List returns the list of user's teams.
func (c *Client) List(opts *ListOptions) ([]*team.Team, error) {
	c.init()

	req := &stack.TeamListRequest{}
	if opts != nil {
		req.Slug = opts.Slug
	}

	resp := stack.TeamListResponse{}
	if err := c.kloud().Call("team.list", req, &resp); err != nil {
		return nil, err
	}

	return resp.Teams, nil
}

func (c *Client) Whoami() (*stack.WhoamiResponse, error) {
	c.init()

	var resp stack.WhoamiResponse

	if err := c.kloud().Call("team.whoami", nil, &resp); err != nil {
		return nil, err
	}

	return &resp, nil
}

func (c *Client) Close() (err error) {
	if c.used.Valid() == nil {
		err = c.kloud().Cache().ReadWrite().SetValue("team.used", &c.used)
	}

	return err
}

func (c *Client) init() {
	c.once.Do(c.readCache)
}

func (c *Client) readCache() {
	// Ignoring read error, if it's non-nil then empty cache is going to
	// be used instead.
	_ = c.kloud().Cache().ReadOnly().GetValue("team.used", &c.used)
}

func (c *Client) kloud() *kloud.Client {
	if c.Kloud != nil {
		return c.Kloud
	}
	return kloud.DefaultClient
}

func Use(team *Team)                               { DefaultClient.Use(team) }
func Used() *Team                                  { return DefaultClient.Used() }
func List(opts *ListOptions) ([]*team.Team, error) { return DefaultClient.List(opts) }
func Whoami() (*stack.WhoamiResponse, error)       { return DefaultClient.Whoami() }
