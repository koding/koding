package remoteapi

import (
	"errors"
	"sync"
	"time"

	"koding/api"
	"koding/klientctl/config"
	"koding/klientctl/ctlcli"
	"koding/klientctl/endpoint"
	"koding/klientctl/endpoint/auth"
	"koding/klientctl/endpoint/kloud"
	"koding/klientctl/endpoint/team"
	"koding/remoteapi"
	"koding/remoteapi/client"
	account "koding/remoteapi/client/j_account"
	"koding/remoteapi/models"
)

// ErrNotFound is returned by Client methods when a requested
// resource was not found.
var ErrNotFound = errors.New("resource was not found")

// DefaultClient is a default remote.api client.
//
// It uses default kloud client as auth provider
// and kd cache for storing authentication tokens.
var DefaultClient = &Client{}

func init() {
	// Ensure DefaultClient is closed on exit.
	ctlcli.CloseOnExit(DefaultClient)
}

// DefaultTimeout defines max remote.api request time,
// after which the request is cancelled.
var DefaultTimeout = 30 * time.Second

// Client is a wrapper for remote.api client that takes
// care of authorization and caching.
type Client struct {
	Kloud  *kloud.Client  // if nil, kloud.DefaultClient is used
	Auth   *auth.Client   // if nil, auth.DefaultClient is used
	Team   *team.Client   // if nil, team.DefaultClient is used
	Client *client.Koding // if nil, new client is created (with kloud as auth provider)

	once     sync.Once // for c.init()
	api      *remoteapi.Client
	c        *client.Koding
	accounts map[string]*models.JAccount
}

// New creates new remoteapi client for the given user.
func (c *Client) New(user *api.User) *client.Koding {
	c.init()

	return c.api.New(user)
}

// Close flushes all underlying caches and closes all clients.
func (c *Client) Close() (err error) {
	if len(c.accounts) != 0 {
		err = c.kloud().Cache().ReadWrite().SetValue("jAccounts", c.accounts)
	}
	return err
}

// AccountByUsername looks up the jAccount by the given username.
func (c *Client) AccountByUsername(username string) (*models.JAccount, error) {
	c.init()

	// TODO(rjeczalik): Make a wrapper type for c.accounts and move the lookup there.
	for _, account := range c.accounts {
		if account.Profile.Nickname == username {
			return account, nil
		}
	}

	params := &account.JAccountOneParams{
		Body: map[string]string{"profile.nickname": username},
	}

	params.SetTimeout(c.timeout())

	resp, err := c.client().JAccount.JAccountOne(params, nil)
	if err != nil {
		return nil, err
	}

	var account models.JAccount

	if err := remoteapi.Unmarshal(resp.Payload, &account); err != nil {
		return nil, err
	}

	c.accounts[account.ID] = &account

	return &account, nil
}

// Account looks up the jAccount by the given filter value.
func (c *Client) Account(filter *models.JAccount) (*models.JAccount, error) {
	c.init()

	if filter.ID != "" {
		if account, ok := c.accounts[filter.ID]; ok {
			return account, nil
		}
	}

	params := &account.JAccountOneParams{
		Body: filter,
	}

	params.SetTimeout(c.timeout())

	resp, err := c.client().JAccount.JAccountOne(params, nil)
	if err != nil {
		return nil, err
	}

	var account models.JAccount

	if err := remoteapi.Unmarshal(resp.Payload, &account); err != nil {
		return nil, err
	}

	c.accounts[account.ID] = &account

	return &account, nil
}

func (c *Client) init() {
	c.once.Do(c.initClient)
}

func (c *Client) initClient() {
	c.accounts = make(map[string]*models.JAccount)

	// Ignoring read error, if it's non-nil then empty cache is going to
	// be used instead.
	_ = c.kloud().Cache().ReadOnly().GetValue("jAccounts", &c.accounts)

	if c.Client == nil {
		c.api = &remoteapi.Client{
			Transport: endpoint.Transport(c.kloud(), c.auth()),
			Endpoint:  config.Konfig.Endpoints.Koding.Public.URL,
		}
		c.c = c.api.New(&api.User{
			Username: c.kloud().Username(),
			Team:     c.team().Used().Name,
		})
	}

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

func (c *Client) client() *client.Koding {
	if c.Client != nil {
		return c.Client
	}
	return c.c
}

func (c *Client) auth() *auth.Client {
	if c.Auth != nil {
		return c.Auth
	}
	return auth.DefaultClient
}

func (c *Client) timeout() time.Duration {
	if c.api != nil {
		return c.api.Timeout()
	}
	return DefaultTimeout
}

func AccountByUsername(username string) (*models.JAccount, error) {
	return DefaultClient.AccountByUsername(username)
}

func Account(filter *models.JAccount) (*models.JAccount, error) {
	return DefaultClient.Account(filter)
}
