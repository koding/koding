package config

import (
	"sync"

	"koding/kites/config"
	"koding/kites/config/configstore"
	"koding/kites/kloud/stack"
	"koding/klientctl/ctlcli"
	"koding/klientctl/endpoint/kloud"
)

var DefaultClient = &Client{}

type Client struct {
	Kloud *kloud.Client

	once     sync.Once // for c.init()
	store    *configstore.Client
	cache    *config.Cache
	defaults config.Konfigs
}

func (c *Client) Used() (*config.Konfig, error) {
	c.init()

	return c.store.Used()
}

func (c *Client) Use(k *config.Konfig) error {
	c.init()

	return c.store.Use(k)
}

func (c *Client) List() config.Konfigs {
	c.init()

	return c.store.List()
}

func (c *Client) Set(key, value string) error {
	c.init()

	return c.store.Set(key, value)
}

func (c *Client) Close() (err error) {
	c.init()

	if len(c.defaults) != 0 {
		err = c.cache.SetValue("konfigs.default", c.defaults)
	}

	return nonil(err, c.cache.Close())
}

func (c *Client) Defaults() (*config.Konfig, error) {
	c.init()

	return c.fetchDefaults(false)
}

func (c *Client) fetchDefaults(force bool) (*config.Konfig, error) {
	used, err := c.store.Used()
	if err != nil {
		return nil, err
	}

	id := used.ID()

	if !force {
		if defaults, ok := c.defaults[id]; ok {
			return defaults, nil
		}
	}

	var req = &stack.ConfigMetadataRequest{}
	var resp stack.ConfigMetadataResponse

	if err := c.kloud().Call("config.metadata", req, &resp); err != nil {
		return nil, err
	}

	defaults := &config.Konfig{
		Endpoints: resp.Metadata.Endpoints,
	}

	c.defaults[defaults.ID()] = defaults

	return defaults, nil
}

type ResetOpts struct {
	Force bool
}

func (c *Client) Reset(opts *ResetOpts) error {
	c.init()

	used, err := c.store.Used()
	if err != nil {
		return err
	}

	defaults, err := c.fetchDefaults(opts.Force)
	if err != nil {
		return err
	}

	used.Endpoints = defaults.Endpoints

	return c.store.Use(used)
}

func (c *Client) init() {
	c.once.Do(c.initClient)
}

func (c *Client) initClient() {
	c.store = &configstore.Client{}
	c.cache = config.NewCache(c.store.CacheOptions("konfig"))
	c.defaults = make(config.Konfigs)

	c.store.Cache = c.cache

	// Ignoring read error, if it's non-nil then empty cache is going to
	// be used instead.
	_ = c.cache.GetValue("konfigs.default", &c.defaults)

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

func List() config.Konfigs              { return DefaultClient.List() }
func Set(key, value string) error       { return DefaultClient.Set(key, value) }
func Use(k *config.Konfig) error        { return DefaultClient.Use(k) }
func Used() (*config.Konfig, error)     { return DefaultClient.Used() }
func Defaults() (*config.Konfig, error) { return DefaultClient.Defaults() }
func Reset(opts *ResetOpts) error       { return DefaultClient.Reset(opts) }
