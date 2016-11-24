package credential

import (
	"errors"
	"fmt"
	"sync"

	"koding/kites/kloud/stack"
	"koding/klientctl/ctlcli"
	"koding/klientctl/kloud"
)

// DefaultClient
var DefaultClient = &Client{}

// ListOptions
type ListOptions struct {
	Team     string
	Provider string
}

// CreateOptions
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

// Client
type Client struct {
	Kloud *kloud.Client

	once   sync.Once // for c.init()
	cached stack.Credentials
	used   map[string]string
}

// List
func (c *Client) List(opts *ListOptions) (stack.Credentials, error) {
	c.init()

	var req *stack.CredentialListRequest
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

// Create
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

	return &stack.CredentialItem{
		Title:      resp.Title,
		Team:       req.Team,
		Identifier: resp.Identifier,
	}, nil
}

// Use
func (c *Client) Use(identifier string) error {
	c.init()

	provider, err := c.Provider(identifier)
	if err != nil {
		return err
	}

	c.used[provider] = identifier

	return nil
}

// User
func (c *Client) Used() map[string]string {
	c.init()

	return c.used
}

// Provider
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

// Close
func (c *Client) Close() (err error) {
	if len(c.cached) != 0 {
		err = nonil(
			c.kloud().Cache().SetValue("credentials", c.cached),
			c.kloud().Cache().SetValue("credentials.used", c.used),
		)
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

	// Ignoring read error, if it's non-nil then empty cache is going to
	// be used instead.
	_ = c.kloud().Cache().GetValue("credentials", &c.cached)
	_ = c.kloud().Cache().GetValue("credentials.used", &c.used)

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
func Use(identifier string) error                               { return DefaultClient.Use(identifier) }
func Used() map[string]string                                   { return DefaultClient.Used() }
func Provider(identifier string) (string, error)                { return DefaultClient.Provider(identifier) }
