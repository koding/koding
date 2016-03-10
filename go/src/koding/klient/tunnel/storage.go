package tunnel

import (
	"encoding/json"
	"errors"

	"github.com/boltdb/bolt"
)

type Storage interface {
	Options() (*Options, error)
	UpdateOptions(*Options) error
}

func newStorage(opts *Options) Storage {
	b, err := newBoltStorage(opts.DB)
	if err == nil {
		return b
	}

	opts.Log.Warning("tunnel: unable to open BoltDB: %s", err)

	return newMemStorage()
}

var (
	// dbBucket is the bucket name used to retrieve and store the resolved
	// address
	dbBucket  = []byte("klienttunnel")
	dbOptions = []byte("options")
)

type boltStorage struct {
	db *bolt.DB
}

func newBoltStorage(db *bolt.DB) (*boltStorage, error) {
	if db == nil {
		return nil, errors.New("no local database")
	}
	b := &boltStorage{
		db: db,
	}

	if err := b.init(); err != nil {
		return nil, err
	}

	return b, nil
}

func (b *boltStorage) init() error {
	return b.db.Update(func(tx *bolt.Tx) (err error) {
		if tx.Bucket(dbBucket) == nil {
			_, err = tx.CreateBucket(dbBucket)
		}
		return err
	})
}

func (b *boltStorage) Options() (*Options, error) {
	var opts Options
	err := b.db.View(func(tx *bolt.Tx) error {
		p := tx.Bucket(dbBucket).Get(dbOptions)
		if len(p) == 0 {
			return errors.New("not found")
		}

		return json.Unmarshal(p, &opts)
	})

	if err != nil {
		return nil, err
	}

	return &opts, nil
}

func (b *boltStorage) UpdateOptions(opts *Options) error {
	p, err := json.Marshal(opts)
	if err != nil {
		return err
	}

	return b.db.Update(func(tx *bolt.Tx) error {
		return tx.Bucket(dbBucket).Put(dbOptions, p)
	})
}

type memStorage struct {
	opts *Options
}

func newMemStorage() *memStorage {
	return &memStorage{
		opts: &Options{},
	}
}

func (m *memStorage) Options() (*Options, error) {
	return m.opts.copy(), nil
}

func (m *memStorage) UpdateOptions(opts *Options) error {
	m.opts = opts.copy()
	return nil
}
