package config

import (
	"os"
	"os/user"
	"path/filepath"

	"koding/klient/storage"

	"github.com/boltdb/bolt"
)

// CurrentUser represents current user that owns the KD process.
//
// If the process was started with sudo, the CurrentUser represents
// the user that invoked sudo.
var CurrentUser = currentUser()

// CacheOptions are used to configure Cache behavior for New method.
type CacheOptions struct {
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
func NewCache(options *CacheOptions) *Cache {
	db, _ := newBoltDB(options)

	return &Cache{
		EncodingStorage: storage.NewEncodingStorage(db, options.Bucket),
	}
}

// NewCache returns new cache value backed by BoltDB.
func NewBoltCache(options *CacheOptions) (*Cache, error) {
	db, err := newBoltDB(options)
	if err != nil {
		return nil, err
	}

	bolt, err := storage.NewBoltStorageBucket(db, options.Bucket)
	if err != nil {
		return nil, err
	}

	return &Cache{
		EncodingStorage: &storage.EncodingStorage{
			Interface: bolt,
		},
	}, nil
}

func newBoltDB(o *CacheOptions) (*bolt.DB, error) {
	os.MkdirAll(filepath.Dir(o.File), 0755)

	return bolt.Open(o.File, 0644, o.BoltDB)
}

func KodingHome() string {
	home := os.Getenv("KODING_HOME")

	if _, err := os.Stat(home); err != nil {
		home = filepath.Join(CurrentUser.HomeDir, ".config", "koding")
	}

	return home
}

func currentUser() *user.User {
	u, err := user.Current()
	if err != nil {
		panic(err)
	}

	if u.Uid != "0" {
		return u
	}

	u2, err := user.Lookup(os.Getenv("SUDO_USER"))
	if err != nil {
		return u
	}

	return u2
}
