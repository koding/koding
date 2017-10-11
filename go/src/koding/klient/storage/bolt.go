package storage

import (
	"errors"
	"fmt"

	"github.com/boltdb/bolt"
)

var DataBucket = []byte("userdata")

// boltdb satisfies https://godoc.org/github.com/koding/cache#Cache interface
type boltdb struct {
	bucketName []byte
	*bolt.DB
}

// NewBoltStorage returns a new boltdb
func NewBoltStorage(db *bolt.DB) (*boltdb, error) {
	return NewBoltStorageBucket(db, nil)
}

// NewBoltStorageBucket returns a new boltdb with a custom bucket name.
func NewBoltStorageBucket(db *bolt.DB, bucketName []byte) (*boltdb, error) {
	if db == nil {
		return nil, errors.New("boltDB reference is nil")
	}

	b := &boltdb{
		bucketName: bucketName,
		DB:         db,
	}

	if !db.IsReadOnly() {
		if err := b.Update(func(tx *bolt.Tx) error {
			_, err := tx.CreateBucketIfNotExists(b.bucket())
			return err
		}); err != nil {
			return nil, errors.New("error ensuring bucket exists: " + err.Error())
		}
	}

	return b, nil
}

func (b *boltdb) bucket() []byte {
	if b.bucketName != nil {
		return b.bucketName
	}

	return DataBucket
}

// Set adds the given key/value pair to the db
func (b *boltdb) Set(key, value string) error {
	return b.DB.Update(func(tx *bolt.Tx) error {
		b := tx.Bucket(b.bucket())
		return b.Put([]byte(key), []byte(value))
	})
}

// Get returns the value for the given key
func (b *boltdb) Get(key string) (string, error) {
	var res string
	if err := b.DB.View(func(tx *bolt.Tx) error {
		bkt := tx.Bucket(b.bucket())
		if bkt == nil {
			return fmt.Errorf("bucket %q does not exist", b.bucket())
		}
		v := bkt.Get([]byte(key))
		res = string(v)
		return nil
	}); err != nil {
		return "", err
	}

	if res == "" {
		return "", ErrKeyNotFound
	}

	return res, nil
}

// Delete deletes the value associated with the given key
func (b *boltdb) Delete(key string) error {
	return b.DB.Update(func(tx *bolt.Tx) error {
		b := tx.Bucket(b.bucket())
		return b.Delete([]byte(key))
	})
}
