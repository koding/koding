package bongo

import (
	"encoding/json"
	"strings"

	"github.com/koding/redis"
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

// Basic requirements for a model for working with caching system
type Cacher interface {
	CachePrefix(id int64) string
	GetForCache(id int64) (string, error)
	Cacheable
}

type Cacheable interface {
	GetCacheId() int64
}

func (b *Bongo) GetFromBest(i Modellable, data Cacher, id int64) error {
	var d string
	var err error

	// check if cache is enabled
	if b.Cache == nil {
		// try to get data from getter func
		d, err = data.GetForCache(id)
		if err != nil {
			return err
		}
	} else {
		// get data from cache
		d, err = b.getFromCacheHelper(data, id)
		if err != nil {
			return err
		}
	}

	// marshall it to the `modellable`
	return json.NewDecoder(strings.NewReader(d)).Decode(i)
}

func (b *Bongo) SetToCache(data Cacher) error {
	// check if  cache is enabled
	if b.Cache == nil {
		return ErrCacheIsNotEnabled
	}

	return b.setToCacheHelper(data, data.GetCacheId())

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
	d, err := service.GetForCache(id)
	if err != nil {
		return "", err
	}

	// after getting data, set it to cache
	// since we have the data, no need to handle error here
	err = b.putHelper(service.CachePrefix(id), d)
	if err != nil {
		b.log.Error("Error occurred while setting data to cache %v", err.Error())
	}

	return d, nil
}

func (b *Bongo) setToCacheHelper(service Cacher, id int64) error {
	// try to get data from getter func
	d, err := service.GetForCache(id)
	if err != nil {
		return err
	}

	// after getting data, set it to cache
	// since we have the data, no need to handle error here
	return b.putHelper(service.CachePrefix(id), d)
}

func (b *Bongo) putHelper(id, data string) error {
	return b.Cache.Set(id, data)
}
