package collaboration

import (
	"encoding/json"
	"errors"

	"github.com/boltdb/bolt"
)

const UserBucket = "users"

// boltdb satisfies Storage interface
type boltdb struct {
	*bolt.DB
}

// Tx is our own transaction type which provides helper methods
type Tx struct {
	*bolt.Tx
}

// NewBoltStorage returns a new boltdb
func NewBoltStorage(db *bolt.DB) (*boltdb, error) {
	if db == nil {
		return nil, errors.New("boltDB reference is nil")
	}

	b := &boltdb{}
	b.DB = db

	if err := b.Update(func(tx *Tx) error {
		_, err := tx.CreateBucketIfNotExists([]byte(UserBucket))
		if err != nil {
			return err
		}
		return nil
	}); err != nil {
		return nil, err
	}

	return b, nil
}

// Get returns the value of a given username
func (b *boltdb) Get(username string) (*Option, error) {
	var option *Option
	err := b.View(func(tx *Tx) error {
		value := tx.User(username)
		if len(value) == 0 {
			return ErrUserNotFound
		}

		// don't unmarshall an empty string, this is probably due the old db
		if string(value) == "" {
			return nil
		}

		return json.Unmarshal([]byte(value), &option)
	})

	return option, err
}

// GetAll fetches all keys which are unique usernames in the bucket.
func (b *boltdb) GetAll() (map[string]*Option, error) {
	options := make(map[string]*Option, 0)

	err := b.View(func(tx *Tx) error {
		return tx.Bucket([]byte(UserBucket)).ForEach(func(k, v []byte) error {
			var option *Option

			// we don't return an error, because of the old data which is pure
			// string
			if err := json.Unmarshal(v, &option); err == nil {
				options[string(k)] = option
			}

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
