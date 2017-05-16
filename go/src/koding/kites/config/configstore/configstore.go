package configstore

import (
	"encoding/json"
	"errors"
	"fmt"
	"io/ioutil"
	"log"
	"net/url"
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
	Cache     *config.Cache        // if nil, a new db will be opened during each operation
	CacheOpts *config.CacheOptions // if nil, defaultCacheOpts are going to be used
	Home      string               // uses config.KodingHome by default
	Mounts    string               // uses config.KodingMounts by default
	Owner     *config.User         // uses config.CurrentUser by default

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
		var used usedKonfig
		var konfigs = make(config.Konfigs)

		if err := cache.GetValue("konfigs.used", &used); err != nil {
			return err
		}

		if err := cache.GetValue("konfigs", &konfigs); err != nil {
			return err
		}

		if mixin, ok := konfigs[used.ID]; ok {
			if err := mergeIn(k, mixin); err != nil {
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

	oldFile := filepath.Join(c.home(), app+".bolt")
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
	_ = util.Chown(dir, c.owner().User)

	return &config.CacheOptions{
		File: file,
		BoltDB: &bolt.Options{
			Timeout: 3 * time.Second,
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
		// Best-effort attempt to ensure data in klient.bolt is consistent.
		// Ignore any error, as there's no recovery from corrupted
		// configuration, other than reinstalling kd / klient.
		return migrateKonfigBolt(cache)
	})
}

func (c *Client) boltFile(app string) string {
	if used, err := c.Used(); err == nil && app != "konfig" {
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

func (c *Client) Commit(fn func(*config.Cache) error) error {
	c.init()

	return c.commit(fn)
}

func (c *Client) commit(fn func(*config.Cache) error) error {
	if c.Cache != nil {
		return fn(c.Cache)
	}

	cache, err := config.NewBoltCache(c.cacheOpts())
	if err != nil {
		return err
	}

	return nonil(fn(cache), cache.Close())
}

func (c *Client) home() string {
	if c.Home != "" {
		return c.Home
	}
	return config.KodingHome()
}

func (c *Client) mounts() string {
	if c.Mounts != "" {
		return c.Mounts
	}
	return config.KodingMounts()
}

func (c *Client) owner() *config.User {
	if c.Owner != nil {
		return c.Owner
	}
	return config.CurrentUser
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
		konfigs := make(config.Konfigs)

		if err := cache.GetValue("konfigs", &konfigs); isFatal(err) {
			return err
		}

		id := konfig.ID()

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
			if oldKonfig.Endpoints == nil {
				oldKonfig.Endpoints = &config.Endpoints{}
			}

			if u, err := url.Parse(oldKonfig.KontrolURL); err == nil && oldKonfig.KontrolURL != "" {
				u.Path = ""
				oldKonfig.Endpoints.Koding = config.NewEndpointURL(u)
			}

			if oldKonfig.TunnelURL != "" {
				oldKonfig.Endpoints.Tunnel = config.NewEndpoint(oldKonfig.TunnelURL)
			}

			// Best-effort attempt to ensure /etc/kite/kite.key is stored
			// in ~/.config/koding/konfig.bolt, so it is possible to
			// use kd / konfig with koding deployments that sign with
			// different kontrol keys, e.g. production <-> sandbox or
			// production <-> self-hosted opensource version.
			_ = migrateKiteKey(&oldKonfig)

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

func migrateKiteKey(konfig *config.Konfig) error {
	// KiteKey already exists in the DB - we don't care
	// whether it's our one or user overridden it explictely
	// as long as it's there.
	if konfig.KiteKey != "" {
		return nil
	}

	defaultKitekey := config.NewKonfig(&config.Environments{Env: konfig.Environment}).KiteKeyFile
	if defaultKitekey == "" {
		defaultKitekey = filepath.FromSlash("/etc/kite/kite.key")
	}

	kitekey := konfig.KiteKeyFile

	if kitekey == "" {
		kitekey = defaultKitekey
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

	if konfig.KiteKeyFile == defaultKitekey {
		konfig.KiteKeyFile = ""
	}

	konfig.KiteKey = string(p)

	return nil
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

func SetFlatKeyValue(m map[string]interface{}, key, value string) error {
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

	if err := SetFlatKeyValue(m, key, value); err != nil {
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
func Commit(fn func(*config.Cache) error) error    { return DefaultClient.Commit(fn) }
func List() config.Konfigs                         { return DefaultClient.List() }
func Read(e *config.Environments) *config.Konfig   { return DefaultClient.Read(e) }
func Set(key, value string) error                  { return DefaultClient.Set(key, value) }
func Use(k *config.Konfig) error                   { return DefaultClient.Use(k) }
func Used() (*config.Konfig, error)                { return DefaultClient.Used() }
