package main

import (
	"path/filepath"
	"time"

	cfg "koding/kites/config"
	"koding/klientctl/config"
	"koding/klientctl/ctlcli"

	"github.com/boltdb/bolt"
	"github.com/koding/kite"
	"github.com/koding/kite/protocol"
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

func Kite() *kite.Kite {
	if k != nil {
		return k
	}

	k = kite.New(config.Name, config.KiteVersion)
	k.Config = config.Konfig.KiteConfig()
	k.Config.Environment = config.Environment
	k.Log = log

	return k
}

func Kloud() (*kite.Client, error) {
	const timeout = 4 * time.Second

	c := Kite().NewClient(config.Konfig.KloudURL)

	if err := c.DialTimeout(timeout); err != nil {
		query := &protocol.KontrolQuery{
			Name:        "kloud",
			Environment: config.Environment,
		}

		clients, err := Kite().GetKites(query)
		if err != nil {
			return nil, err
		}

		c = Kite().NewClient(clients[0].URL)

		if err := c.DialTimeout(timeout); err != nil {
			return nil, err
		}
	}

	c.Auth = &kite.Auth{
		Type: "kiteKey",
		Key:  Kite().Config.KiteKey,
	}

	return c, nil
}
