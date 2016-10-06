package config

import (
	"os"
	"path/filepath"
	"time"

	"koding/klient/storage"

	"github.com/boltdb/bolt"
)

// DefaultFile is a default location of BoltDB file for KD, which is used
// as a temporary cache.
var DefaultOptions = &Options{
	File: filepath.Join(CurrentUser.HomeDir, ".config", "koding", "config.bolt"),
	BoltDB: &bolt.Options{
		Timeout: 1 * time.Second,
	},
	Bucket: []byte("kd"),
}

// Options are used to configure Cache behavior for New method.
type Options struct {
	File   string
	BoltDB *bolt.Options
	Bucket []byte
}

// Cache is a file-based cached used to persist values between
// different runs of kd tool.
type Cache struct {
	*storage.EncodingStorage
}

// NewCache returns new cache value.
//
// If it was not possible to create or open BoltDB database,
// an in-memory cache is created.
//
// If options are nil, DefaultOptions are used instead.
func NewCache(options *Options) *Cache {
	if options == nil {
		options = DefaultOptions
	}

	return &Cache{
		EncodingStorage: storage.NewEncodingStorage(newBoltDB(options), options.Bucket),
	}
}

func newBoltDB(o *Options) *bolt.DB {
	os.MkdirAll(filepath.Dir(o.File), 0755)

	if db, err := bolt.Open(o.File, 0644, o.BoltDB); err == nil {
		return db
	}

	return nil
}
