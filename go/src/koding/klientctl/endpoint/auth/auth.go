package auth

import (
	"sort"
	"sync"

	"koding/kites/kloud/stack"
	"koding/klientctl/ctlcli"
	"koding/klientctl/endpoint/kloud"
)

var DefaultClient = &Client{}

type Session struct {
	ClientID string `json:"clientID"`
	Team     string `json:"team"`
}

type Sessions map[string]Session

func (s Sessions) Slice() []Session {
	keys := make([]string, 0, len(s))

	for k := range s {
		keys = append(keys, k)
	}

	sort.Strings(keys)

	slice := make([]Session, 0, len(s))

	for _, k := range keys {
		slice = append(slice, s[k])
	}

	return slice
}

type LoginOptions struct {
	Team string
}

type Client struct {
	Kloud *kloud.Client

	once     sync.Once // for c.init()
	sessions Sessions
}

func (c *Client) Login(opts *LoginOptions) (*Session, error) {
	c.init()

	req := &stack.LoginRequest{
		GroupName: opts.Team,
	}

	var resp stack.LoginResponse

	// We ignore any cached session for the given login request,
	// as it might be already invalid from a different client.
	if err := c.kloud().Call("auth.login", req, &resp); err != nil {
		return nil, err
	}

	session := Session{
		ClientID: resp.ClientID,
		Team:     resp.GroupName,
	}

	c.sessions[session.Team] = session

	return &session, nil
}

func (c *Client) Sessions() Sessions {
	c.init()

	return c.sessions
}

func (c *Client) Close() (err error) {
	if len(c.sessions) != 0 {
		err = c.kloud().Cache().SetValue("auth.sessions", c.sessions)
	}

	return err
}

func (c *Client) init() {
	c.once.Do(c.readCache)
}

func (c *Client) readCache() {
	c.sessions = make(Sessions)

	// Ignoring read error, if it's non-nil then empty cache is going to
	// be used instead.
	_ = c.kloud().Cache().GetValue("auth.sessions", &c.sessions)

	// Flush cache on exit.
	ctlcli.CloseOnExit(c)
}

func (c *Client) kloud() *kloud.Client {
	if c.Kloud != nil {
		return c.Kloud
	}
	return kloud.DefaultClient
}

func Login(opts *LoginOptions) (*Session, error) { return DefaultClient.Login(opts) }
