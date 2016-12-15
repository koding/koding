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

// Transport is an interface that abstracts underlying
// RPC round trip.
//
// Default implementation used in this package is
// a kiteTransport, but plain net/rpc can also be
// used.
type Transport interface {
	Call(method string, arg, reply interface{}) error
	Valid() error
}

// DefaultClient is a default client used by Cache, Kite,
// KiteConfig and Kloud functions.
var DefaultClient = &Client{
	Transport: &KiteTransport{
		DialTimeout: 30 * time.Second,
		TellTimeout: 60 * time.Second,
	},
}

// Client is responsible for communication with Kloud kite.
type Client struct {
	// Log is used for logging.
	Log logging.Logger

	// Transport is used for RPC communication.
	Transport Transport

	cache *cfg.Cache
}

func (c *Client) Cache() *cfg.Cache {
	if c.cache != nil {
		return c.cache
	}

	c.cache = cfg.NewCache(kdCacheOpts)
	ctlcli.CloseOnExit(c.cache)

	return c.cache
}

func (c *Client) Username() string {
	if kt, ok := c.Transport.(*KiteTransport); ok {
		return kt.kiteConfig().Username
	}
	return cfg.CurrentUser.Username
}

func (c *Client) Call(method string, arg, reply interface{}) error {
	return c.Transport.Call(method, arg, reply)
}

// KiteTransport is a default transport that uses github.com/koding/kite
// for underlying communication.
type KiteTransport struct {
	// DialTimeout is a maximum time external kite is
	// going to be dialed for.
	DialTimeout time.Duration

	// TellTimeout is a maximum time of kite's
	// request/response roundtrip.
	TellTimeout time.Duration

	// Log is used for logging.
	Log logging.Logger

	k      *kite.Kite
	kCfg   *kitecfg.Config
	kKloud *kite.Client
}

var _ Transport = (*KiteTransport)(nil)

func (kt *KiteTransport) Call(method string, arg, reply interface{}) error {
	k, err := kt.kloud()
	if err != nil {
		return err
	}

	r, err := k.TellWithTimeout(method, kt.TellTimeout, arg)
	if err != nil {
		return err
	}

	if reply != nil {
		return r.Unmarshal(reply)
	}

	return nil
}

func (kt *KiteTransport) kite() *kite.Kite {
	if kt.k != nil {
		return kt.k
	}

	kt.k = kite.New(config.Name, config.KiteVersion)
	kt.k.Config = kt.kiteConfig()
	kt.k.Log = kt.Log

	return kt.k
}

func (kt *KiteTransport) kiteConfig() *kitecfg.Config {
	if kt.kCfg != nil {
		return kt.kCfg
	}

	kt.kCfg = config.Konfig.KiteConfig()
	kt.kCfg.KontrolURL = config.Konfig.Endpoints.Kontrol().Public.String()
	kt.kCfg.Environment = config.Environment
	kt.kCfg.Transport = kitecfg.XHRPolling

	return kt.kCfg
}

func (kt *KiteTransport) kloud() (*kite.Client, error) {
	if kt.kKloud != nil {
		return kt.kKloud, nil
	}

	kloud := kt.kite().NewClient(config.Konfig.Endpoints.Kloud().Public.String())

	if err := kloud.DialTimeout(kt.DialTimeout); err != nil {
		query := &protocol.KontrolQuery{
			Name:        "kloud",
			Environment: kt.kiteConfig().Environment,
		}

		clients, err := kt.kite().GetKites(query)
		if err != nil {
			return nil, err
		}

		kloud = kt.kite().NewClient(clients[0].URL)

		if err := kloud.DialTimeout(kt.DialTimeout); err != nil {
			return nil, err
		}
	}

	kt.kKloud = kloud
	kt.kKloud.Auth = &kite.Auth{
		Type: "kiteKey",
		Key:  kt.kiteConfig().KiteKey,
	}

	return kt.kKloud, nil
}

func (kt *KiteTransport) Valid() error {
	// In order to test whether we're able to authenticate with kloud
	// we need to call some kite method. For that purpose we
	// use builtin "kite.print" method with empty string, since
	// this is the only nop method available.
	return kt.Call("kite.print", "", nil)
}

func Cache() *cfg.Cache { return DefaultClient.Cache() }
func Username() string  { return DefaultClient.Username() }
func Call(method string, arg, reply interface{}) error {
	return DefaultClient.Call(method, arg, reply)
}
