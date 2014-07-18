package bongo

import (
	"encoding/json"
	"errors"
	"strings"

	"github.com/koding/redis"
)

var (
	ErrCacheIsNotEnabled = errors.New("cache is not enabled")
)

// A generic key value storage interface. Implementations must be thread safe.
// The storage can be anything.
type Cache interface {
	// Get retrieves data from the storage.
	Get(key string) (string, error)

	// Set puts data into the storage.
	Set(key string, item string) error

	// TODO implement Delete, MultiGet, MultiSet
}

type Cacher interface {
	CachePrefix(id int64) string
	CacheGet(id int64) (string, error)
	CacheSet(data Cachable) (string, error)
	Cachable
}

type Cachable interface {
	GetCacheId() int64
}

func (b *Bongo) getFromCacheHelper(service Cacher, id int64) (string, error) {
	data, err := b.Cache.Get(service.CachePrefix(id))
	// if not err, return early
	if err == nil {
		return data, nil
	}

	// if error isnt nilErr, return
	// TODO this redis err should not be here
	if err != redis.ErrNil {
		return "", err
	}

	// try to get data from getter func
	d, err := service.CacheGet(id)
	if err != nil {
		return "", err
	}

	// after getting data, set it to cache
	// since we have the data, no need to handle error here
	b.putHelper(service.CachePrefix(id), d)

	return d, nil
}

func (b *Bongo) setToCacheHelper(service Cacher, data Cachable) error {
	d, err := service.CacheSet(data)
	if err != nil {
		return err
	}

	return b.putHelper(service.CachePrefix(data.GetCacheId()), d)
}

func (b *Bongo) putHelper(id, data string) error {
	return b.Cache.Set(id, data)
}

func (b *Bongo) SetToCache(data Cacher) error {
	// check if  cache is enabled
	if b.Cache == nil {
		return ErrCacheIsNotEnabled
	}

	return b.setToCacheHelper(data, data)

}

func (b *Bongo) GetFromCache(i Modellable, data Cacher, id int64) error {
	// check if  cache is enabled
	if b.Cache == nil {
		return ErrCacheIsNotEnabled
	}

	str, err := b.getFromCacheHelper(data, id)
	if err != nil {
		return err
	}

	err = json.NewDecoder(strings.NewReader(str)).Decode(i)
	if err != nil {
		return err
	}

	return nil
}
