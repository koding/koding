package credential

import (
	"errors"
	"fmt"
	"sync"

	"koding/kites/kloud/stack"
	"koding/klientctl/ctlcli"
	"koding/klientctl/endpoint/kloud"
)

var DefaultClient = &Client{}

type ListOptions struct {
	Team     string
	Provider string
}

type CreateOptions struct {
	Team     string
	Provider string
	Title    string
	Data     []byte
}

// Valid implements the stack.Validator interface.
func (opts *CreateOptions) Valid() error {
	if opts == nil {
		return errors.New("credential: arguments are missing")
	}

	if len(opts.Data) == 0 {
		return errors.New("credential: data is missing")
	}

	return nil
}

type Client struct {
	Kloud *kloud.Client

	once     sync.Once // for c.init()
	cached   stack.Credentials
	used     map[string]string
	describe map[string]*stack.Description
}

func (c *Client) List(opts *ListOptions) (stack.Credentials, error) {
	c.init()

	var req = &stack.CredentialListRequest{}
	var resp stack.CredentialListResponse

	if opts != nil {
		req = &stack.CredentialListRequest{
			Team:     opts.Team,
			Provider: opts.Provider,
		}
	}

	if err := c.kloud().Call("credential.list", req, &resp); err != nil {
		return nil, err
	}

	c.cache(resp.Credentials)

	return resp.Credentials, nil
}

func (c *Client) Create(opts *CreateOptions) (*stack.CredentialItem, error) {
	c.init()

	if err := opts.Valid(); err != nil {
		return nil, err
	}

	req := &stack.CredentialAddRequest{
		Provider: opts.Provider,
		Team:     opts.Team,
		Title:    opts.Title,
		Data:     opts.Data,
	}

	var resp stack.CredentialAddResponse

	if err := c.kloud().Call("credential.add", req, &resp); err != nil {
		return nil, err
	}

	c.cached[opts.Provider] = append(c.cached[opts.Provider], stack.CredentialItem{
		Identifier: resp.Identifier,
		Title:      resp.Title,
		Team:       opts.Team,
		Provider:   opts.Provider,
	})

	return &stack.CredentialItem{
		Title:      resp.Title,
		Team:       req.Team,
		Identifier: resp.Identifier,
	}, nil
}

func (c *Client) Use(identifier string) error {
	c.init()

	provider, err := c.Provider(identifier)
	if err != nil {
		return err
	}

	c.used[provider] = identifier

	return nil
}

func (c *Client) Used() map[string]string {
	c.init()

	return c.used
}

func (c *Client) Provider(identifier string) (provider string, err error) {
	c.init()

	if cred, ok := c.cached.Find(identifier); ok {
		return cred.Provider, nil
	}

	creds, err := c.List(nil)
	if err != nil {
		return "", err
	}

	c.cache(creds)

	if cred, ok := c.cached.Find(identifier); ok {
		return cred.Provider, nil
	}

	return "", fmt.Errorf("credential: %q does not exist or is not shared with the user", identifier)
}

func (c *Client) Describe() (stack.Descriptions, error) {
	c.init()

	var req stack.CredentialDescribeRequest
	var resp stack.CredentialDescribeResponse

	if err := c.kloud().Call("credential.describe", &req, &resp); err != nil {
		return nil, err
	}

	c.describe = resp.Description

	return c.describe, nil
}

func (c *Client) Close() (err error) {
	if len(c.cached) != 0 {
		err = c.kloud().Cache().SetValue("credential", c.cached)
	}

	if len(c.used) != 0 {
		err = nonil(err, c.kloud().Cache().SetValue("credential.used", c.used))
	}

	if len(c.describe) != 0 {
		err = nonil(err, c.kloud().Cache().SetValue("credential.describe", c.describe))
	}

	return err
}

func (c *Client) cache(credentials stack.Credentials) {
	c.init()

	for provider, creds := range credentials {
		if len(creds) == 0 {
			continue
		}

		if identifier, ok := c.used[provider]; !ok || identifier == "" {
			c.used[provider] = creds[0].Identifier
		}

		if _, ok := c.cached[provider]; !ok {
			c.cached[provider] = creds
			continue
		}

		for _, cred := range creds {
			if _, ok := c.cached.Find(cred.Identifier); ok {
				continue
			}

			c.cached[provider] = append(c.cached[provider], cred)
		}
	}
}

func (c *Client) init() {
	c.once.Do(c.readCache)
}

func (c *Client) readCache() {
	c.cached = make(stack.Credentials)
	c.used = make(map[string]string)
	c.describe = make(map[string]*stack.Description)

	// Ignoring read error, if it's non-nil then empty cache is going to
	// be used instead.
	_ = c.kloud().Cache().GetValue("credential", &c.cached)
	_ = c.kloud().Cache().GetValue("credential.used", &c.used)
	_ = c.kloud().Cache().GetValue("credential.describe", &c.describe)

	// Flush cache on exit.
	ctlcli.CloseOnExit(c)
}

func (c *Client) kloud() *kloud.Client {
	if c.Kloud != nil {
		return c.Kloud
	}

	return kloud.DefaultClient
}

func nonil(err ...error) error {
	for _, e := range err {
		if e != nil {
			return e
		}
	}

	return nil
}

func List(opts *ListOptions) (stack.Credentials, error)         { return DefaultClient.List(opts) }
func Create(opts *CreateOptions) (*stack.CredentialItem, error) { return DefaultClient.Create(opts) }
func Describe() (stack.Descriptions, error)                     { return DefaultClient.Describe() }
func Use(identifier string) error                               { return DefaultClient.Use(identifier) }
func Used() map[string]string                                   { return DefaultClient.Used() }
func Provider(identifier string) (string, error)                { return DefaultClient.Provider(identifier) }
