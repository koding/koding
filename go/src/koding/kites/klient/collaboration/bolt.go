package collaboration

import (
	"os"
	"os/user"
	"path/filepath"
	"time"

	"github.com/boltdb/bolt"
)

const (
	UserBucket = "users"
	// Canonical database path is `$HOME + DatabasePath`
	DatabasePath = "/.config/koding/klient.bolt"
)

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

// boltdb satisfies Storage interface
type boltdb struct {
	*bolt.DB
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
func (b *boltdb) Get(username string) (string, error) {
	var user string

	err := b.View(func(tx *Tx) error {
		value := tx.User(username)
		if len(value) == 0 {
			return ErrUserNotFound
		}
		user = value
		return nil
	})

	if err != nil {
		return "", err
	}

	return user, nil
}

// GetAll fetches all keys which are unique usernames in the bucket.
func (b *boltdb) GetAll() ([]string, error) {
	users := make([]string, 0)

	err := b.View(func(tx *Tx) error {
		tx.Bucket([]byte(UserBucket)).ForEach(func(k, _ []byte) error {
			users = append(users, string(k))
			return nil
		})
		return nil
	})

	if err != nil {
		return nil, err
	}
	return users, nil
}

// Set assigns the value for the given username
func (b *boltdb) Set(username, value string) error {
	return b.Update(func(tx *Tx) error {
		return tx.SetUser(username, value)
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

// Tx is our own transaction type which provides helper methods
type Tx struct {
	*bolt.Tx
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
