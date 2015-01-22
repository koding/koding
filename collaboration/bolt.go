package collaboration

import (
	"encoding/json"
	"os"
	"os/user"
	"path/filepath"
	"time"

	"github.com/koding/klient/Godeps/_workspace/src/github.com/boltdb/bolt"
)

const (
	UserBucket = "users"
	// Canonical database path is `$HOME + DatabasePath`
	DatabasePath = "/.config/koding/klient.bolt"
)

// boltdb satisfies Storage interface
type boltdb struct {
	*bolt.DB
}

// Tx is our own transaction type which provides helper methods
type Tx struct {
	*bolt.Tx
}

// NewBoltStorage returns a new boltdb
func NewBoltStorage() (*boltdb, error) {
	d := &boltdb{}

	// Ensure data directory exists.
	u, err := user.Current()
	if err != nil {
		return nil, err
	}
	boltPath := u.HomeDir + DatabasePath
	if err := os.MkdirAll(filepath.Dir(boltPath), 0755); err != nil {
		return nil, err
	}

	if err := d.open(boltPath); err != nil {
		return nil, err
	}

	return d, nil
}

func (b *boltdb) open(dbpath string) error {
	var err error
	b.DB, err = bolt.Open(dbpath, 0644, &bolt.Options{Timeout: 5 * time.Second})
	if err != nil {
		return err
	}

	return b.Update(func(tx *Tx) error {
		_, err := tx.CreateBucketIfNotExists([]byte(UserBucket))
		if err != nil {
			return err
		}
		return nil
	})
}

// Get returns the value of a given username
func (b *boltdb) Get(username string) (*Option, error) {
	var option *Option
	err := b.View(func(tx *Tx) error {
		value := tx.User(username)
		if len(value) == 0 {
			return ErrUserNotFound
		}

		return json.Unmarshal([]byte(value), option)
	})

	return option, err
}

// GetAll fetches all keys which are unique usernames in the bucket.
func (b *boltdb) GetAll() (map[string]*Option, error) {
	options := make(map[string]*Option, 0)

	err := b.View(func(tx *Tx) error {
		return tx.Bucket([]byte(UserBucket)).ForEach(func(k, v []byte) error {
			var option *Option
			if err := json.Unmarshal([]byte(v), option); err != nil {
				return err
			}

			options[string(k)] = option
			return nil
		})
	})

	return options, err
}

// Set assigns the value for the given username
func (b *boltdb) Set(username string, option *Option) error {
	v, err := json.Marshal(option)
	if err != nil {
		return err
	}

	return b.Update(func(tx *Tx) error {
		return tx.SetUser(username, string(v))
	})
}

// Delete deletes the given username key and value from the bucket
func (b *boltdb) Delete(username string) error {
	return b.Update(func(tx *Tx) error {
		return tx.DeleteUser(username)
	})
}

// Close closes the boltdb database for further read and writes
func (b *boltdb) Close() error {
	return b.DB.Close()
}

// View executes a function in the context of a read-only transaction.
func (b *boltdb) View(fn func(*Tx) error) error {
	return b.DB.View(func(tx *bolt.Tx) error {
		return fn(&Tx{tx})
	})
}

// Update executes a function in the context of a writable transaction.
func (b *boltdb) Update(fn func(*Tx) error) error {
	return b.DB.Update(func(tx *bolt.Tx) error {
		return fn(&Tx{tx})
	})
}

// User retrieves a users field by name.
func (tx *Tx) User(key string) string {
	return string(tx.Bucket([]byte(UserBucket)).Get([]byte(key)))
}

// SetUser sets the value of a users field by name.
func (tx *Tx) SetUser(key, value string) error {
	return tx.Bucket([]byte(UserBucket)).Put([]byte(key), []byte(value))
}

// DeleteUser deletes the key of a users field by name.
func (tx *Tx) DeleteUser(key string) error {
	return tx.Bucket([]byte(UserBucket)).Delete([]byte(key))
}
