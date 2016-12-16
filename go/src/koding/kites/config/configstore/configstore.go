package configstore

import (
	"encoding/json"
	"errors"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"

	"koding/kites/config"
	"koding/kites/kloud/utils/object"
	"koding/klient/storage"
	"koding/tools/util"

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

	once sync.Once // for c.init()
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

	return c.commit(makeUseFunc(k))
}

func (c *Client) Used() (*config.Konfig, error) {
	c.init()

	var konfig config.Konfig

	if err := c.commit(makeUsedFunc(&konfig)); err != nil {
		return nil, err
	}

	return &konfig, nil
}

func (c *Client) CacheOptions(app string) *config.CacheOptions {
	c.init()

	oldFile := filepath.Join(config.KodingHome(), app+".bolt")
	file := c.boltFile(app)

	if _, err := os.Stat(file); oldFile != file && os.IsNotExist(err) {
		if _, err := os.Stat(oldFile); err == nil {
			// Bolt file exists in old location but not in the new one,
			// most likely we just migrated from old config version.
			if err := os.Rename(oldFile, file); err != nil {
				// If it's not possible to move - symlink.
				if e := os.Symlink(oldFile, file); e != nil {
					log.Printf("unable to move old bolt file to new location %q: %s, %s", file, err, e)
				}
			}
		}
	}

	dir := filepath.Dir(file)

	// Best-effort attempts, ignore errors.
	_ = os.MkdirAll(dir, 0755)
	_ = util.Chown(dir, config.CurrentUser.User)

	return &config.CacheOptions{
		File: file,
		BoltDB: &bolt.Options{
			Timeout: 5 * time.Second,
		},
		Bucket: []byte(app),
	}
}

func (c *Client) Set(key, value string) error {
	return c.commit(func(cache *config.Cache) error {
		var used usedKonfig
		var konfigs = make(config.Konfigs)

		if err := cache.GetValue("konfigs.used", &used); err != nil {
			return err
		}

		if err := cache.GetValue("konfigs", &konfigs); err != nil {
			return err
		}

		k, ok := konfigs[used.ID]
		if !ok {
			return storage.ErrKeyNotFound
		}

		if err := setKonfig(k, key, value); err != nil {
			return fmt.Errorf("failed to update %s=%s: %s", key, value, err)
		}

		return cache.SetValue("konfigs", konfigs)
	})
}

func (c *Client) init() {
	c.once.Do(c.initClient)
}

func (c *Client) initClient() {
	// TODO(rjeczalik): various migrations are perform in the init method
	// to ensure old kd / klients that has old boltdb databases
	// continue to work. When we're sure it's no longer needed, this
	// code should be removed.
	_ = c.commit(func(cache *config.Cache) error {
		return nonil(
			// Best-effort attempt to ensure data in klient.bolt is consistent.
			// Ignore any error, as there's no recovery from corrupted
			// configuration, other than reinstalling kd / klient.
			//
			// This migration must be executed before kite.key one.
			migrateKonfigBolt(cache),

			// Best-effort attemp to ensure /etc/kite/kite.key is stored
			// in ~/.config/koding/konfig.bolt, so it is possible to
			// use kd / konfig with koding deployments that sign with
			// different kontrol keys, e.g. production <-> sandbox or
			// production <-> self-hosted opensource version.
			migrateKiteKey(cache),
		)
	})
}

func (c *Client) boltFile(app string) string {
	if used, err := c.Used(); err == nil {
		return filepath.Join(config.KodingHome(), app+"."+used.ID()+".bolt")
	}
	return filepath.Join(config.KodingHome(), app+".bolt")
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

func makeUsedFunc(konfig *config.Konfig) func(cache *config.Cache) error {
	return func(cache *config.Cache) error {
		var used usedKonfig

		if err := cache.GetValue("konfigs.used", &used); err != nil {
			return err
		}

		var konfigs config.Konfigs

		if err := cache.GetValue("konfigs", &konfigs); err != nil {
			return err
		}

		if k, ok := konfigs[used.ID]; ok {
			*konfig = *k
			return nil
		}

		return errors.New("config not found - use one that exists")
	}
}

func makeUseFunc(konfig *config.Konfig) func(cache *config.Cache) error {
	return func(cache *config.Cache) error {
		id := konfig.ID()

		konfigs := make(config.Konfigs)

		if err := cache.GetValue("konfigs", &konfigs); isFatal(err) {
			return err
		}

		konfigs[id] = konfig

		return nonil(
			cache.SetValue("konfigs", konfigs),
			cache.SetValue("konfigs.used", &usedKonfig{ID: id}),
		)
	}
}

func migrateKonfigBolt(cache *config.Cache) error {
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
}

func migrateKiteKey(cache *config.Cache) error {
	var konfig config.Konfig

	if err := makeUsedFunc(&konfig)(cache); err != nil {
		return err
	}

	// KiteKey already exists in the DB - we don't care
	// whether it's our one or user overriden it explictely
	// as long as it's there.
	if konfig.KiteKey != "" {
		return nil
	}

	kitekey := konfig.KiteKeyFile
	if kitekey == "" {
		kitekey = config.NewKonfig(&config.Environments{Env: konfig.Environment}).KiteKeyFile
	}

	if _, err := os.Stat(kitekey); err != nil {
		// Either no access to the file or it does not exist,
		// in either case nothing to do here.
		return nil
	}

	p, err := ioutil.ReadFile(kitekey)
	if err != nil {
		return err
	}

	konfig.KiteKey = string(p)

	return makeUseFunc(&konfig)(cache)
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

func setFlatKeyValue(m map[string]interface{}, key, value string) error {
	keys := strings.Split(key, ".")
	it := m
	last := len(keys) - 1

	for _, key := range keys[:last] {
		switch v := it[key].(type) {
		case map[string]interface{}:
			it = v
		case nil:
			newV := make(map[string]interface{})
			it[key] = newV
			it = newV
		default:
			return errors.New("key is not an object")
		}
	}

	if value == "" {
		delete(it, keys[last])
	} else {
		it[keys[last]] = value
	}

	return nil
}

func setKonfig(cfg *config.Konfig, key, value string) error {
	m := make(map[string]interface{})

	p, err := json.Marshal(cfg)
	if err != nil {
		return err
	}

	if err := json.Unmarshal(p, &m); err != nil {
		return err
	}

	if err := setFlatKeyValue(m, key, value); err != nil {
		return err
	}

	if p, err = json.Marshal(m); err != nil {
		return err
	}

	if value == "" {
		*cfg = config.Konfig{}
	}

	return json.Unmarshal(p, cfg)
}

func nonil(err ...error) error {
	for _, e := range err {
		if e != nil {
			return e
		}
	}
	return nil
}

func CacheOptions(app string) *config.CacheOptions { return DefaultClient.CacheOptions(app) }
func List() config.Konfigs                         { return DefaultClient.List() }
func Read(e *config.Environments) *config.Konfig   { return DefaultClient.Read(e) }
func Set(key, value string) error                  { return DefaultClient.Set(key, value) }
func Use(k *config.Konfig) error                   { return DefaultClient.Use(k) }
func Used() (*config.Konfig, error)                { return DefaultClient.Used() }
