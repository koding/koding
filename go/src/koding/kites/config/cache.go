package config

import (
	"log"
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
	Owner  *user.User
}

func (o *CacheOptions) owner() *user.User {
	if o.Owner != nil {
		return o.Owner
	}
	return CurrentUser
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
	db, err := newBoltDB(options)
	if err != nil {
		log.Println(err)
	}

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
	dir := filepath.Dir(o.File)
	os.MkdirAll(dir, 0755)
	chown(dir, o.owner())

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

	if sudoU, err := user.Lookup(os.Getenv("SUDO_USER")); err == nil {
		return sudoU
	}

	if rootU, err := user.Lookup(os.Getenv("USERNAME")); err == nil {
		return rootU
	}

	return u
}
