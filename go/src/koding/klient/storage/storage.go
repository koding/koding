package storage

import (
	"encoding/json"
	"errors"

	"github.com/boltdb/bolt"
	"github.com/koding/kite"
)

var ErrKeyNotFound = errors.New("key not found")

// Interface should be satisfied by a storage implementation
type Interface interface {
	Get(key string) (string, error)
	Set(key, value string) error
	Delete(key string) error
	Close() error
}

// ValueInterfaces is an interface for encoding storage.
type ValueInterface interface {
	GetValue(key string, value interface{}) error
	SetValue(key string, value interface{}) error
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

type ErrStorage struct {
	Err error
}

var _ Interface = ErrStorage{}

func (es ErrStorage) Get(key string) (string, error) { return "", es.Err }
func (es ErrStorage) Set(key, value string) error    { return es.Err }
func (es ErrStorage) Delete(key string) error        { return es.Err }
func (es ErrStorage) Close() error                   { return es.Err }

type EncodingStorage struct {
	Interface

	MarshalFunc   func(interface{}) ([]byte, error)
	UnmarshalFunc func([]byte, interface{}) error
}

var _ ValueInterface = (*EncodingStorage)(nil)

func NewEncodingStorage(db *bolt.DB, bucketName []byte) *EncodingStorage {
	if boltdb, err := NewBoltStorageBucket(db, bucketName); err == nil {
		return &EncodingStorage{
			Interface: boltdb,
		}
	}

	return &EncodingStorage{
		Interface: NewMemoryStorage(),
	}
}

func (es *EncodingStorage) marshal(v interface{}) ([]byte, error) {
	if es.MarshalFunc != nil {
		return es.MarshalFunc(v)
	}

	return json.Marshal(v)
}

func (es *EncodingStorage) unmarshal(p []byte, v interface{}) error {
	if es.UnmarshalFunc != nil {
		return es.UnmarshalFunc(p, v)
	}

	return json.Unmarshal(p, v)
}

func (es *EncodingStorage) GetValue(key string, value interface{}) error {
	v, err := es.Interface.Get(key)
	if err != nil {
		return err
	}

	return es.unmarshal([]byte(v), value)
}

func (es *EncodingStorage) SetValue(key string, value interface{}) error {
	v, err := es.marshal(value)
	if err != nil {
		return err
	}

	return es.Interface.Set(key, string(v))
}
