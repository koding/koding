package kloud

import (
	"path/filepath"
	"time"

	cfg "koding/kites/config"
	"koding/klientctl/config"
	"koding/klientctl/ctlcli"

	"github.com/boltdb/bolt"
	"github.com/koding/kite"
	kitecfg "github.com/koding/kite/config"
	"github.com/koding/kite/protocol"
	"github.com/koding/logging"
)

var kdCacheOpts = &cfg.CacheOptions{
	File: filepath.Join(cfg.KodingHome(), "kd.bolt"),
	BoltDB: &bolt.Options{
		Timeout: 5 * time.Second,
	},
	Bucket: []byte("kd"),
}

// DefaultClient is a default client used by Cache, Kite,
// KiteConfig and Kloud functions.
var DefaultClient = &Client{
	DialTimeout: 30 * time.Second,
	TellTimeout: 60 * time.Second,
}

// Client is responsible for communication with Kloud kite.
type Client struct {
	// Log is used for logging.
	Log logging.Logger

	// DialTimeout is a maximum time external kite is
	// going to be dialed for.
	DialTimeout time.Duration

	// TellTimeout is a maximum time of kite's
	// request/response roundtrip.
	TellTimeout time.Duration

	cache *cfg.Cache
	k     *kite.Kite
	kCfg  *kitecfg.Config
	kloud *kite.Client
}

// Cache
func (c *Client) Cache() *cfg.Cache {
	if c.cache != nil {
		return c.cache
	}

	c.cache = cfg.NewCache(kdCacheOpts)
	ctlcli.CloseOnExit(c.cache)

	return c.cache
}

// Kite
func (c *Client) Kite() *kite.Kite {
	if c.k != nil {
		return c.k
	}

	c.k = kite.New(config.Name, config.KiteVersion)
	c.k.Config = config.Konfig.KiteConfig()
	c.k.Config.KontrolURL = config.Konfig.KontrolURL
	c.k.Config.Environment = config.Environment
	c.k.Config.Transport = kitecfg.XHRPolling
	c.k.Log = c.Log

	return c.k
}

// KiteConfig
func (c *Client) KiteConfig() *kitecfg.Config {
	if c.kCfg != nil {
		return c.kCfg
	}

	c.kCfg = config.Konfig.KiteConfig()
	c.kCfg.KontrolURL = config.Konfig.KontrolURL
	c.kCfg.Environment = config.Environment
	c.kCfg.Transport = kitecfg.XHRPolling

	return c.kCfg
}

// Kloud
func (c *Client) Kloud() (*kite.Client, error) {
	if c.kloud != nil {
		return c.kloud, nil
	}

	kloud := c.Kite().NewClient(config.Konfig.KloudURL)

	if err := kloud.DialTimeout(c.DialTimeout); err != nil {
		query := &protocol.KontrolQuery{
			Name:        "kloud",
			Environment: c.KiteConfig().Environment,
		}

		clients, err := c.Kite().GetKites(query)
		if err != nil {
			return nil, err
		}

		kloud = c.Kite().NewClient(clients[0].URL)

		if err := kloud.DialTimeout(c.DialTimeout); err != nil {
			return nil, err
		}
	}

	c.kloud = kloud
	c.kloud.Auth = &kite.Auth{
		Type: "kiteKey",
		Key:  c.KiteConfig().KiteKey,
	}

	return c.kloud, nil
}

// Tell
func (c *Client) Tell(method string, in, out interface{}) error {
	k, err := c.Kloud()
	if err != nil {
		return err
	}

	r, err := k.TellWithTimeout(method, c.TellTimeout, in)
	if err != nil {
		return err
	}

	return r.Unmarshal(out)
}

func Cache() *cfg.Cache            { return DefaultClient.Cache() }
func Kite() *kite.Kite             { return DefaultClient.Kite() }
func KiteConfig() *kitecfg.Config  { return DefaultClient.KiteConfig() }
func Kloud() (*kite.Client, error) { return DefaultClient.Kloud() }
