// Package tunnel is responsible of setting up and connecting to a tunnel
// server.
package tunnel

import (
	"encoding/json"
	"errors"
	"strings"
	"sync"

	"koding/kites/tunnelproxy"

	"github.com/boltdb/bolt"
	"github.com/koding/kite"
)

var (
	// dbBucket is the bucket name used to retrieve and store the resolved
	// address
	dbBucket  = []byte("klienttunnel")
	dbOptions = []byte("options")
)

var (
	ErrKeyNotFound = errors.New("key not found")
	ErrNoDatabase  = errors.New("local database is not available")
)

type TunnelOptions struct {
	TunnelName    string `json:"tunnelName"`
	TunnelKiteURL string `json:"tunnelKiteURL,omitempty"`
	VirtualHost   string `json:"VirtualHost,omitempty"`
}

type TunnelClient struct {
	db     *bolt.DB
	client *tunnelproxy.Client
	opts   *TunnelOptions
	log    kite.Logger

	// Used to wait for first successful
	// tunnel server registration.
	register sync.WaitGroup
	once     sync.Once
}

// NewClient returns a new tunnel client instance.
func NewClient(db *bolt.DB, log kite.Logger) *TunnelClient {
	t := &TunnelClient{
		db:   db,
		log:  log,
		opts: &TunnelOptions{},
	}

	t.register.Add(1)

	if err := t.loadOptions(); err != nil {
		t.log.Warning("unable to load tunnel defaults: %s", err)
	}

	return t
}

func (t *TunnelClient) loadOptions() error {
	if t.db == nil {
		return ErrNoDatabase
	}

	var p []byte

	err := t.db.View(func(tx *bolt.Tx) error {
		b := tx.Bucket(dbBucket)
		if b == nil {
			return ErrKeyNotFound
		}

		p = b.Get(dbOptions)

		if len(p) == 0 {
			return ErrKeyNotFound
		}

		return nil
	})

	if err != nil {
		return err
	}

	var opts TunnelOptions
	if err = json.Unmarshal(p, &opts); err != nil {
		return err
	}

	t.opts = &opts
	return nil
}

func (t *TunnelClient) saveOptions() error {
	if t.db == nil {
		return ErrNoDatabase
	}

	p, err := json.Marshal(t.opts)
	if err != nil {
		return err
	}

	return t.db.Update(func(tx *bolt.Tx) error {
		b, err := t.bucket(tx)
		if err != nil {
			return err
		}

		return b.Put(dbOptions, p)
	})
}

func guessTunnelName(vhost string) string {
	// If vhost is <tunnelName>.<user>.koding.me return the
	// <tunnelName> part (production environment).
	//
	// Example: 62ee1f899a4e.rafal.koding.me
	i := strings.LastIndex(vhost, ".koding.me")
	if i != -1 {
		i = strings.LastIndex(vhost[:i], ".")
		if i != -1 {
			return vhost[:i]
		}
	}

	// If vhost is <tunnelName>.<customBaseVirtualHost> return the
	// <tunnelName> part (development environment).
	//
	// Example: macbook.rafal.t.dev.koding.io:8081
	if strings.Count(vhost, ".") > 1 {
		return vhost[:strings.IndexRune(vhost, '.')]
	}

	return ""
}

func (t *TunnelClient) updateOptions(reg *tunnelproxy.RegisterResult) {
	t.opts.VirtualHost = reg.VirtualHost
	t.opts.TunnelName = guessTunnelName(reg.VirtualHost)
	t.once.Do(t.register.Done)

	if err := t.saveOptions(); err != nil {
		t.log.Warning("unable to update tunnel defaults: %s", err)
	}
}

func (t *TunnelClient) bucket(tx *bolt.Tx) (b *bolt.Bucket, err error) {
	b = tx.Bucket(dbBucket)

	if b == nil {
		b, err = tx.CreateBucketIfNotExists(dbBucket)
		if err != nil {
			return nil, err
		}
	}

	return b, nil
}

func (t *TunnelClient) setDefaults(opts *tunnelproxy.ClientOptions) {
	opts.OnRegister = t.updateOptions

	if opts.TunnelName == "" {
		opts.TunnelName = t.opts.TunnelName
	}

	if opts.TunnelKiteURL == "" {
		opts.TunnelKiteURL = t.opts.TunnelKiteURL
	}

	if opts.LastVirtualHost == "" {
		opts.LastVirtualHost = t.opts.VirtualHost
	}

	if t.opts.TunnelName == "" {
		t.opts.TunnelName = opts.TunnelName
	}

	if t.opts.TunnelKiteURL == "" {
		t.opts.TunnelKiteURL = opts.TunnelKiteURL
	}
}

// Start setups the client and connects to a tunnel server based on the given
// configuration. It's non blocking and should be called only once.
func (t *TunnelClient) Start(opts *tunnelproxy.ClientOptions) (string, error) {
	t.setDefaults(opts)

	t.log.Debug("starting tunnel client: %# v", opts)

	client, err := tunnelproxy.NewClient(opts)
	if err != nil {
		return "", err
	}

	t.client = client
	t.client.Start()
	t.register.Wait()

	return t.opts.VirtualHost, nil
}
