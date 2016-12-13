package configstore

import (
	"encoding/json"
	"path/filepath"
	"sync"
	"time"

	"koding/kites/config"
	"koding/kites/kloud/utils/object"
	"koding/klient/storage"

	"github.com/boltdb/bolt"
)

var defaultCacheOpts = &config.CacheOptions{
	File: filepath.Join(config.KodingHome(), "konfig.bolt"),
	BoltDB: &bolt.Options{
		Timeout: 5 * time.Second,
	},
	Bucket: []byte("konfig"),
}

var DefaultClient = &Client{}

type Client struct {
	CacheOpts *config.CacheOptions

	once     sync.Once // for c.init()
	konfigID string
	konfig   *config.Konfig
}

type usedKonfig struct {
	ID string `json:"id"`
}

func (c *Client) List() (k config.Konfigs) {
	c.init()

	_ = c.commit(func(cache *config.Cache) error {
		return cache.GetValue("konfigs", &k)
	})

	return k
}

func (c *Client) Read(e *config.Environments) *config.Konfig {
	c.init()

	k := config.NewKonfig(e)

	_ = c.commit(func(cache *config.Cache) error {
		var mixin config.Konfig

		if err := cache.GetValue("konfig", &mixin); err == nil {
			if err := mergeIn(k, &mixin); err != nil {
				return err
			}
		}

		return nil
	})

	return k
}

func (c *Client) Use(k *config.Konfig) error {
	c.init()

	if err := k.Valid(); err != nil {
		return err
	}

	id := k.ID()

	return c.commit(func(cache *config.Cache) error {
		konfigs := make(config.Konfigs)

		if err := cache.GetValue("konfigs", &konfigs); isFatal(err) {
			return err
		}

		konfigs[id] = k

		return nonil(
			cache.SetValue("konfigs", konfigs),
			cache.SetValue("konfigs.used", &usedKonfig{ID: id}),
		)
	})
}

func (c *Client) init() {
	c.once.Do(c.initClient)
}

func (c *Client) initClient() {
	// Best-effort attempt to ensure data in klient.bolt is consistent.
	// Ignore any error, as there's no recovery from corrupted
	// configuration, other than reinstalling kd / klient.
	_ = c.commit(func(cache *config.Cache) error {
		var used usedKonfig
		var oldKonfig config.Konfig
		var konfigs = make(config.Konfigs)

		if err := cache.GetValue("konfig", &oldKonfig); isFatal(err) {
			return err
		}

		if err := cache.GetValue("konfigs", &konfigs); isFatal(err) {
			return err
		}

		if err := cache.GetValue("konfigs.used", &used); isFatal(err) {
			return err
		}

		// If old konfig exists, try to migrate it over to konfigs.
		if oldKonfig.Valid() == nil {
			id := oldKonfig.ID()

			if _, ok := konfigs[id]; !ok {
				konfigs[id] = &oldKonfig

				_ = cache.SetValue("konfigs", konfigs)
			}
		}

		// If no konfig is in use (e.g. we just migrated one),
		// try to set to the default one.
		if used.ID == "" && len(konfigs) == 1 {
			for id, konfig := range konfigs {
				if konfig.Valid() == nil {
					_ = cache.SetValue("konfigs.used", &usedKonfig{ID: id})
				}
				break
			}
		}

		return nil
	})
}

func (c *Client) cacheOpts() *config.CacheOptions {
	if c.CacheOpts != nil {
		return c.CacheOpts
	}
	return defaultCacheOpts
}

func (c *Client) commit(fn func(*config.Cache) error) error {
	cache := config.NewCache(c.cacheOpts())
	return nonil(fn(cache), cache.Close())
}

func isFatal(err error) bool {
	return err != nil && err != storage.ErrKeyNotFound
}

func mergeIn(kfg, mixin *config.Konfig) error {
	p, err := json.Marshal(object.Inline(mixin, kfg))
	if err != nil {
		return err
	}

	return json.Unmarshal(p, kfg)
}

func nonil(err ...error) error {
	for _, e := range err {
		if e != nil {
			return e
		}
	}
	return nil
}

func List() config.Konfigs                       { return DefaultClient.List() }
func Read(e *config.Environments) *config.Konfig { return DefaultClient.Read(e) }
func Use(k *config.Konfig) error                 { return DefaultClient.Use(k) }
