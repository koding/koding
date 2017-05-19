package storage

import (
	"errors"

	"github.com/koding/klient/Godeps/_workspace/src/github.com/boltdb/bolt"
	"github.com/koding/klient/Godeps/_workspace/src/github.com/koding/kite"
)

var ErrKeyNotFound = errors.New("key not found")

// Interface should be satisfied by a storage implementation
type Interface interface {
	Get(key string) (string, error)
	Set(key, value string) error
	Delete(key string) error
}

type Storage struct {
	Interface
}

func New(boltDB *bolt.DB) *Storage {
	var db Interface
	var err error

	// Try the persistent storage first. If it fails, try the in-memory one.
	db, err = NewBoltStorage(boltDB)
	if err != nil {
		db = NewMemoryStorage()
	}

	return &Storage{
		Interface: db,
	}
}

func (s *Storage) GetValue(r *kite.Request) (interface{}, error) {
	var params struct {
		Key string
	}

	if err := r.Args.One().Unmarshal(&params); err != nil {
		return nil, err
	}

	if params.Key == "" {
		return nil, errors.New("key is empty")
	}

	return s.Get(params.Key)
}

func (s *Storage) SetValue(r *kite.Request) (interface{}, error) {
	var params struct {
		Key   string
		Value string
	}

	if err := r.Args.One().Unmarshal(&params); err != nil {
		return nil, err
	}

	if params.Key == "" {
		return nil, errors.New("key is empty")
	}

	if params.Value == "" {
		return nil, errors.New("value is empty")
	}

	if err := s.Set(params.Key, params.Value); err != nil {
		return nil, err
	}

	return true, nil
}

func (s *Storage) DeleteValue(r *kite.Request) (interface{}, error) {
	var params struct {
		Key string
	}

	if err := r.Args.One().Unmarshal(&params); err != nil {
		return nil, err
	}

	if params.Key == "" {
		return nil, errors.New("key is empty")
	}

	if err := s.Delete(params.Key); err != nil {
		return nil, err
	}

	return true, nil
}
