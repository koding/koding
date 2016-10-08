package main

import (
	"time"

	cfg "koding/config"
	"koding/klientctl/config"

	"github.com/koding/kite"
	konfig "github.com/koding/kite/config"
	"github.com/koding/kite/protocol"
)

var (
	cache *cfg.Cache
	k     *kite.Kite
	kloud *kite.Client
)

func Cache() *cfg.Cache {
	if cache != nil {
		return cache
	}

	cache = cfg.NewCache(nil)

	return cache
}

func Kite() *kite.Kite {
	if k != nil {
		return k
	}

	cfg, err := konfig.NewFromKiteKey(config.Konfig.KiteKeyFile)
	if err != nil {
		cfg, err = konfig.Get()
		if err != nil {
			cfg = konfig.New()
		}
	}

	k = kite.New(config.Name, config.KiteVersion)
	k.Config = cfg
	k.Config.KontrolURL = config.Konfig.KontrolURL
	k.Config.Environment = config.Environment
	k.Log = log

	if debug {
		k.SetLogLevel(kite.DEBUG)
	}

	return k
}

func Kloud() (*kite.Client, error) {
	const timeout = 4 * time.Second

	c := Kite().NewClient(cfg.Builtin.Endpoints.URL("kloud", config.Environment))

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
