package config

import (
	"errors"
	"fmt"
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
		return &Cache{
			EncodingStorage: &storage.EncodingStorage{
				Interface: &storage.ErrStorage{Err: err},
			},
		}
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

	// Opening may fail with "bad file descriptor" coming from mmap,
	// when file exists and is 0 in size. Best-effort retry - remove
	// the file and open it again.
	//
	// Reproduced on Fedora 25.
	if fi, err := os.Stat(o.File); (err != nil || fi.Size() == 0) && o.BoltDB.ReadOnly {
		optsCopy := *o.BoltDB
		optsCopy.ReadOnly = false

		db, err := bolt.Open(o.File, 0644, &optsCopy)
		if err == nil {
			err = db.Close()
		}
		if err != nil {
			return nil, fmt.Errorf("error creating BoltDB: %s", err)
		}
	}

	db, err := bolt.Open(o.File, 0644, o.BoltDB)

	_ = util.Chown(o.File, o.owner().User)

	if err != nil {
		return nil, errors.New("error opening config: " + err.Error())
	}

	return db, nil
}

func KodingHome() string {
	home := os.Getenv("KODING_HOME")

	if _, err := os.Stat(home); err != nil {
		home = filepath.Join(CurrentUser.HomeDir, ".config", "koding")
	}

	return home
}

// KodingMounts gives the path of the koding cache directory.
//
// The default value is overwritten with KODING_MOUNTS env,
// if it points to a valid directory.
func KodingMounts() string {
	cache := os.Getenv("KODING_MOUNTS")

	if fi, err := os.Stat(cache); err != nil || !fi.IsDir() {
		cache = filepath.Join(CurrentUser.HomeDir, ".cache", "koding")
	}

	return cache
}

// User is a convenience wrapper for a user.User value.
//
// It provides user.Group informations and it implements
// a flag.Getter interface.
type User struct {
	*user.User
	Uid, Gid int
	Groups   []*user.Group
}

// String implements the fmt.Stringer interface.
func (u *User) String() string {
	if u.User != nil {
		return u.User.Username
	}

	// Workaround for flag package, which calls String()
	// on a zero-value User type.
	return currentStdUser().Username
}

// Set implements the flag.Value interface.
func (u *User) Set(username string) error {
	us, err := user.Lookup(username)
	if err != nil {
		return err
	}

	*u = *newUser(us)

	return nil
}

// Get implements the flag.Getter interface.
func (u *User) Get() interface{} {
	return u
}

func currentUser() *User {
	return newUser(currentStdUser())
}

func newUser(us *user.User) *User {
	u := &User{
		User: us,
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
