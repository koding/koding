package collaboration

import (
	"os"
	"path/filepath"
	"time"

	"github.com/boltdb/bolt"
)

const (
	DatabasePath = "/opt/kites/klient/klient.db"
	UserBucket   = "users"
)

type User struct {
	Username string    `json:"username"`
	SharedAt time.Time `json:"shared_at"`
}

func NewBolt() *DB {
	d := &DB{}

	// Ensure data directory exists.
	dir := filepath.Dir(DatabasePath)
	if err := os.MkdirAll(dir, 0700); err != nil {
		panic(err.Error())
	}

	if err := d.Open(DatabasePath); err != nil {
		panic(err.Error())
	}

	return d
}

// DB satisfies Storage interface
type DB struct {
	*bolt.DB
}

func (db *DB) Open(dbpath string) error {
	var err error
	db.DB, err = bolt.Open(dbpath, 0600, nil)
	if err != nil {
		return err
	}

	return db.Update(func(tx *Tx) error {
		_, err := tx.CreateBucketIfNotExists([]byte(UserBucket))
		if err != nil {
			return err
		}
		return nil
	})
}

func (db *DB) Get(username string) (string, error) {
	var user string

	err := db.View(func(tx *Tx) error {
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
func (db *DB) GetAll() ([]string, error) {
	users := make([]string, 0)

	err := db.View(func(tx *Tx) error {
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

func (db *DB) Set(username, value string) error {
	return db.Update(func(tx *Tx) error {
		return tx.SetUser(username, value)
	})
}

func (db *DB) Delete(username string) error {
	return db.Update(func(tx *Tx) error {
		return tx.DeleteUser(username)
	})
}

func (db *DB) Close() error {
	return db.DB.Close()
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

// View executes a function in the context of a read-only transaction.
func (db *DB) View(fn func(*Tx) error) error {
	return db.DB.View(func(tx *bolt.Tx) error {
		return fn(&Tx{tx})
	})
}

// Update executes a function in the context of a writable transaction.
func (db *DB) Update(fn func(*Tx) error) error {
	return db.DB.Update(func(tx *bolt.Tx) error {
		return fn(&Tx{tx})
	})
}
