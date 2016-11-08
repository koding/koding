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

var (
	cache *cfg.Cache
	k     *kite.Kite
	kloud *kite.Client

	kdCache = &cfg.CacheOptions{
		File: filepath.Join(cfg.KodingHome(), "kd.bolt"),
		BoltDB: &bolt.Options{
			Timeout: 5 * time.Second,
		},
		Bucket: []byte("kd"),
	}
)

func Cache() *cfg.Cache {
	if cache != nil {
		return cache
	}

	cache = cfg.NewCache(kdCache)
	ctlcli.CloseOnExit(cache)

	return cache
}

func Kite(log logging.Logger) *kite.Kite {
	if k != nil {
		return k
	}

	k = kite.New(config.Name, config.KiteVersion)
	k.Config = config.Konfig.KiteConfig()
	k.Config.KontrolURL = config.Konfig.KontrolURL
	k.Config.Environment = config.Environment
	k.Config.Transport = kitecfg.XHRPolling
	k.Log = log

	return k
}

func Kloud(log logging.Logger) (*kite.Client, error) {
	const timeout = 4 * time.Second

	c := Kite(log).NewClient(config.Konfig.KloudURL)

	if err := c.DialTimeout(timeout); err != nil {
		query := &protocol.KontrolQuery{
			Name:        "kloud",
			Environment: config.Environment,
		}

		clients, err := Kite(log).GetKites(query)
		if err != nil {
			return nil, err
		}

		c = Kite(log).NewClient(clients[0].URL)

		if err := c.DialTimeout(timeout); err != nil {
			return nil, err
		}
	}

	c.Auth = &kite.Auth{
		Type: "kiteKey",
		Key:  Kite(log).Config.KiteKey,
	}

	return c, nil
}
