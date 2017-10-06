package config

import (
	"errors"
	"os"
	"time"

	"koding/kites/config"
	"koding/kites/config/configstore"
)

// DefaultCache is a kd.*.bolt database
// for a koding endpoint configured
// in a konfig.bolt database.
var DefaultCache = &Cache{}

// Cacheprovides a read/write access
// to a kd.*.bolt storage file.
//
// Upon init kd uses for read-only access, thus
// multiple kd can be run simultaneously.
//
// Upon exit, kd tries to acquire write access,
// queueing multiple kd processes with a 3s
// timeout.
type Cache struct {
	ro *config.Cache
	rw *config.Cache
}

// Open tries to open new kd storage file.
func Open() (*Cache, error) {
	opts := configstore.CacheOptions("kd")
	opts.BoltDB.Timeout = time.Duration(Konfig.LockTimeout) * time.Second

	// Ensure the database file exists.
	if _, err := os.Stat(opts.File); os.IsNotExist(err) {
		db, err := config.NewBoltCache(opts)
		if err != nil {
			return nil, errors.New("error creating new config: " + err.Error())
		}
		if err := db.Close(); err != nil {
			return nil, errors.New("error closing new config: " + err.Error())
		}
	}

	opts.BoltDB.ReadOnly = true

	ro, err := config.NewBoltCache(opts)
	if err != nil {
		return nil, err
	}

	return &Cache{ro: ro}, nil
}

// ReadOnly gives a cache with read-only access.
//
// Such cache can be use simultaneously by multiple
// processes.
func (c *Cache) ReadOnly() *config.Cache {
	if c.rw != nil {
		return c.rw
	}
	if c.ro == nil {
		opts := configstore.CacheOptions("kd")
		opts.BoltDB.Timeout = time.Duration(Konfig.LockTimeout) * time.Second
		opts.BoltDB.ReadOnly = true

		c.ro = config.NewCache(opts)
	}

	return c.ro
}

// ReadWrite gives a cache with read-write access.
//
// If prior to calling this method a read-only
// access was acquired, it will be released.
func (c *Cache) ReadWrite() *config.Cache {
	if c.rw == nil {
		_ = c.CloseRead()

		opts := configstore.CacheOptions("kd")
		opts.BoltDB.Timeout = time.Duration(Konfig.LockTimeout) * time.Second

		c.rw = config.NewCache(opts)
	}

	return c.rw
}

// CloseRead releases read-only access to a storage file.
func (c *Cache) CloseRead() (err error) {
	if c.ro != nil {
		err = c.ro.Close()
		c.ro = nil
	}
	return err
}

// CloseWrite releases read-write access to a storage file.
func (c *Cache) CloseWrite() (err error) {
	if c.rw != nil {
		err = c.rw.Close()
		c.rw = nil
	}
	return err
}

// Close releases any of the read-only or read-write accesses,
// if acquired.
func (c *Cache) Close() (err error) {
	return nonil(c.CloseWrite(), c.CloseRead())
}
