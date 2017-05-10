package auth

import (
	"errors"
	"sort"
	"sync"

	"koding/api"
	conf "koding/kites/config"
	"koding/kites/kloud/stack"
	"koding/klientctl/config"
	"koding/klientctl/ctlcli"
	"koding/klientctl/endpoint/kloud"
	"koding/klientctl/endpoint/kontrol"
	"koding/klientctl/endpoint/team"
	"koding/klientctl/helper"

	"github.com/koding/kite"
)

// DefaultClient is the default client used by Login, Use and Show.
var DefaultClient = &Client{}

func init() {
	ctlcli.CloseOnExit(DefaultClient)
}

// Session represents user session details required
// for authentication with SocialAPI and remote.api
// endpoints.
type Session struct {
	ClientID string `json:"clientID"` // authentication token
	Team     string `json:"team"`     // authenticated scope
}

// Sessions stores session details for multiple teams.
type Sessions map[string]*Session

// Slice converts the map to a sorted slice.
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

// Info represents authentication details.
type Info struct {
	*Session

	Username string `json:"username,omitempty"`
	BaseURL  string `json:"baseurl,omitempty"`
}

// LoginOptions represents arguments for the Login method.
type LoginOptions struct {
	Team     string // team to authenticate to
	Token    string // optional; use token-based authentication
	Username string // username for password-based authentication
	Password string // password for password-based authentication
	Prefix   string // optional; prefix for interactive mode
	Force    bool   // whether to force new session
}

// AskUserPass asks user for Username and Password in an interactive mode.
func (opts *LoginOptions) AskUserPass() (err error) {
	opts.Username, err = helper.Ask("%sUsername [%s]: ", opts.Prefix, conf.CurrentUser.Username)
	if err != nil {
		return err
	}

	if opts.Username == "" {
		opts.Username = conf.CurrentUser.Username
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

// Client is responsible for authentication by communicating
// with Kloud and Kontrol kites.
type Client struct {
	Kloud   *kloud.Client   // optional; if nil, kloud.DefaultClient is used
	Kontrol *kontrol.Client // optional; if nil, kontrol.DefaultClient is used
	Team    *team.Client    // optional; if nil, team.DefaultClient is used
	Konfig  *conf.Konfig    // optional; if nil, config.Konfig is used

	once     sync.Once // for c.init()
	sessions Sessions
}

var _ api.Storage = (*Client)(nil)

// Get implements the api.Storage interface.
//
// It gives a session for the given team.
//
// All operations on a single Client assume the same user
// (once one logged in with kd auth all commands like
//  kd stack list etc. are going to use the same user).
func (c *Client) Get(u *api.User) (*api.Session, error) {
	c.init()

	s, ok := c.sessions[u.Team]
	if !ok {
		return nil, api.ErrSessionNotFound
	}

	return &api.Session{
		ClientID: s.ClientID,
		User: &api.User{
			Username: c.kloud().Username(),
			Team:     s.Team,
		},
	}, nil
}

// Set implements the api.Storage interface.
//
// It sets or updates session given by the s.
func (c *Client) Set(s *api.Session) error {
	c.init()

	c.sessions[s.User.Team] = &Session{
		ClientID: s.ClientID,
		Team:     s.User.Team,
	}
	return nil
}

// Delete implements the api.Storage interface.
//
// It removes, possibly invalidated, session.
func (c *Client) Delete(s *api.Session) error {
	c.init()

	delete(c.sessions, s.User.Team)
	return nil
}

// Login authenticates to Koding.
//
// If opts.Token is no empty, token-based authentication is used.
//
// If both opts.Username and opts.Password are not empty, password-based
// authentication is used.
//
// Otherwise Login uses kite-based authentication.
func (c *Client) Login(opts *LoginOptions) (*stack.PasswordLoginResponse, error) {
	c.init()

	req := &stack.LoginRequest{
		GroupName: opts.Team,
		Metadata:  true,
	}

	var resp stack.PasswordLoginResponse
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

// Sessions gives all the authenticated sessions.
func (c *Client) Sessions() Sessions {
	c.init()

	return c.sessions
}

// Use caches new user session.
func (c *Client) Use(s *Session) {
	c.init()

	c.sessions[s.Team] = s
}

// Used gives current authentication details.
func (c *Client) Used() *Info {
	session := c.Sessions()[c.team().Used().Name]
	if session == nil {
		session = &Session{}
	}

	if session.Team == "" {
		session.Team = c.team().Used().Name
	}

	return &Info{
		Session:  session,
		Username: c.kloud().Username(),
		BaseURL:  c.konfig().KodingPublic().String(),
	}
}

// Close implements the io.Closer interface.
//
// It closes any resources used by the Client.
func (c *Client) Close() (err error) {
	if len(c.sessions) != 0 {
		err = c.kloud().Cache().ReadWrite().SetValue("auth.sessions", c.sessions)
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
	_ = c.kloud().Cache().ReadOnly().GetValue("auth.sessions", &c.sessions)
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

func (c *Client) konfig() *conf.Konfig {
	if c.Konfig != nil {
		return c.Konfig
	}
	return config.Konfig
}

func nonil(err ...error) error {
	for _, e := range err {
		if e != nil {
			return e
		}
	}
	return nil
}

// Login authenticates to Koding.
//
// If opts.Token is no empty, token-based authentication is used.
//
// If both opts.Username and opts.Password are not empty, password-based
// authentication is used.
//
// Otherwise Login uses kite-based authentication.
//
// The function forwards call to the DefaultClient.
func Login(opts *LoginOptions) (*stack.PasswordLoginResponse, error) {
	return DefaultClient.Login(opts)
}

// Use caches new user session.
//
// The function forwards call to the DefaultClient.
func Use(s *Session) { DefaultClient.Use(s) }

// Used gives current authentication details.
//
// The function forwards call to the DefaultClient.
func Used() *Info { return DefaultClient.Used() }
