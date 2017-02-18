package config

import (
	"log"
	"os"
	"os/user"
	"path/filepath"
	"strconv"

	"koding/klient/storage"
	"koding/tools/util"

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
	Owner  *User
}

func (o *CacheOptions) owner() *User {
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

	// Best-effort attempts, ignore errors.
	_ = os.MkdirAll(dir, 0755)
	_ = util.Chown(dir, o.owner().User)

	return bolt.Open(o.File, 0644, o.BoltDB)
}

func KodingHome() string {
	home := os.Getenv("KODING_HOME")

	if _, err := os.Stat(home); err != nil {
		home = filepath.Join(CurrentUser.HomeDir, ".config", "koding")
	}

	return home
}

func KodingCacheHome() string {
	cache := os.Getenv("KODING_CACHE_HOME")

	if _, err := os.Stat(cache); err != nil {
		cache = filepath.Join(CurrentUser.HomeDir, ".cache", "koding")
	}

	return cache
}

type User struct {
	*user.User
	Uid, Gid int
	Groups   []*user.Group
}

func currentUser() *User {
	u := &User{
		User: currentStdUser(),
	}

	if uid, err := strconv.Atoi(u.User.Uid); err == nil {
		u.Uid = uid
	}

	if gid, err := strconv.Atoi(u.User.Gid); err == nil {
		u.Gid = gid
	}

	ids, err := u.GroupIds()
	if err != nil {
		return u
	}

	for _, id := range ids {
		if g, err := user.LookupGroupId(id); err == nil {
			u.Groups = append(u.Groups, g)
		}
	}

	return u
}

func currentStdUser() *user.User {
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
