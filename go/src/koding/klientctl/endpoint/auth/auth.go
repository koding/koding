package auth

import (
	"errors"
	"sort"
	"sync"

	"koding/kites/config"
	"koding/kites/kloud/stack"
	"koding/klientctl/ctlcli"
	"koding/klientctl/endpoint/kloud"
	"koding/klientctl/endpoint/kontrol"
	"koding/klientctl/endpoint/team"
	"koding/klientctl/helper"

	"github.com/koding/kite"
)

var DefaultClient = &Client{}

func init() {
	ctlcli.CloseOnExit(DefaultClient)
}

type Session struct {
	ClientID string `json:"clientID"`
	Team     string `json:"team"`
}

type Sessions map[string]*Session

func (s Sessions) Slice() []*Session {
	keys := make([]string, 0, len(s))

	for k := range s {
		keys = append(keys, k)
	}

	sort.Strings(keys)

	slice := make([]*Session, 0, len(s))

	for _, k := range keys {
		slice = append(slice, s[k])
	}

	return slice
}

type LoginOptions struct {
	Team     string
	Token    string
	Username string
	Password string
	Prefix   string
	Force    bool
}

func (opts *LoginOptions) AskUserPass() (err error) {
	opts.Username, err = helper.Ask("%sUsername [%s]: ", opts.Prefix, config.CurrentUser.Username)
	if err != nil {
		return err
	}

	if opts.Username == "" {
		opts.Username = config.CurrentUser.Username
	}

	for {
		opts.Password, err = helper.AskSecret("%sPassword [***]: ", opts.Prefix)
		if err != nil {
			return err
		}
		if opts.Password != "" {
			break
		}
	}

	return nil
}

type Client struct {
	Kloud   *kloud.Client
	Kontrol *kontrol.Client
	Team    *team.Client

	once     sync.Once // for c.init()
	sessions Sessions
}

func (c *Client) Login(opts *LoginOptions) (*stack.PasswordLoginResponse, error) {
	c.init()

	req := &stack.LoginRequest{
		GroupName: opts.Team,
		Metadata:  true,
	}

	resp, _ := stack.PasswordLoginResponse{}, error(nil)

	var err error
	// We ignore any cached session for the given login request,
	// as it might be already invalid from a different client.
	if opts.Token != "" {
		req := &kontrol.RegisterRequest{
			AuthType: "token",
			Token:    opts.Token,
		}

		err = c.kontrol().Call("registerMachine", req, &resp.KiteKey)
	} else if opts.Username != "" && opts.Password != "" {
		req := &stack.PasswordLoginRequest{
			LoginRequest: *req,
			Username:     opts.Username,
			Password:     opts.Password,
		}

		err = c.kloud().Call("auth.passwordLogin", req, &resp)
	} else {
		err = c.kloud().Call("auth.login", req, &resp.LoginResponse)
	}

	if e, ok := err.(*kite.Error); ok && e.Type == "kloudError" && e.CodeVal == "415" {
		return nil, errors.New("invalid team name or user does not belong to the team")
	}

	if err != nil {
		return nil, err
	}

	if resp.GroupName != "" {
		session := &Session{
			ClientID: resp.ClientID,
			Team:     resp.GroupName,
		}

		c.sessions[session.Team] = session
	}

	if resp.GroupName == "" {
		resp.GroupName = opts.Team
	}

	return &resp, nil
}

func (c *Client) Sessions() Sessions {
	c.init()

	return c.sessions
}

func (c *Client) Use(s *Session) {
	c.init()

	c.sessions[s.Team] = s
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
}

func (c *Client) kloud() *kloud.Client {
	if c.Kloud != nil {
		return c.Kloud
	}
	return kloud.DefaultClient
}

func (c *Client) kontrol() *kontrol.Client {
	if c.Kontrol != nil {
		return c.Kontrol
	}
	return kontrol.DefaultClient
}

func (c *Client) team() *team.Client {
	if c.Team != nil {
		return c.Team
	}
	return team.DefaultClient
}

func nonil(err ...error) error {
	for _, e := range err {
		if e != nil {
			return e
		}
	}
	return nil
}

func Login(opts *LoginOptions) (*stack.PasswordLoginResponse, error) { return DefaultClient.Login(opts) }
func Use(s *Session)                                                 { DefaultClient.Use(s) }
