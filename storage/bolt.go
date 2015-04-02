package storage

import (
	"errors"

	"github.com/koding/klient/Godeps/_workspace/src/github.com/boltdb/bolt"
)

const DataBucket = "userdata"

// boltdb satisfies https://godoc.org/github.com/koding/cache#Cache interface
type boltdb struct {
	*bolt.DB
}

// NewBoltStorage returns a new boltdb
func NewBoltStorage(db *bolt.DB) (*boltdb, error) {
	if db == nil {
		return nil, errors.New("boltDB reference is nil")
	}

	b := &boltdb{}
	b.DB = db

	if err := b.Update(func(tx *bolt.Tx) error {
		_, err := tx.CreateBucketIfNotExists([]byte(DataBucket))
		if err != nil {
			return err
		}
		return nil
	}); err != nil {
		return nil, err
	}

	return b, nil
}

// Set adds the given key/value pair to the db
func (b *boltdb) Set(key, value string) error {
	return b.DB.Update(func(tx *bolt.Tx) error {
		b := tx.Bucket([]byte(DataBucket))
		return b.Put([]byte(key), []byte(value))
	})
}

// Get returns the value for the given key
func (b *boltdb) Get(key string) (string, error) {
	var res string
	if err := b.DB.View(func(tx *bolt.Tx) error {
		b := tx.Bucket([]byte(DataBucket))
		v := b.Get([]byte(key))
		res = string(v)
		return nil
	}); err != nil {
		return "", err
	}

	return res, nil
}

// Delete deletes the value associated with the given key
func (b *boltdb) Delete(key string) error {
	return b.DB.Update(func(tx *bolt.Tx) error {
		b := tx.Bucket([]byte(DataBucket))
		return b.Delete([]byte(key))
	})
}
