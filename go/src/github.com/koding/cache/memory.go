package cache

import (
	"sync"
	"time"
)

var zeroTTL = time.Duration(0)

type MemoryCache struct {
	// Mutex is used for handling the concurrent
	// read/write requests for cache
	sync.Mutex
	// items holds the cache data
	items map[string]interface{}
	// setAts holds the time that related item's set at
	setAts map[string]time.Time
	// ttl is a duration for a cache key to expire
	ttl time.Duration
	// gcInterval is a duration for garbage collection
	gcInterval time.Duration
}

// NewMemoryCache creates an inmemory cache system
// Which everytime will return the true value about a cache hit
func NewMemory() *MemoryCache {
	return NewMemoryWithTTL(zeroTTL)
}

// NewMemoryCache creates an inmemory cache system
// Which everytime will return the true values about a cache hit
// and never will leak memory
// ttl is used for expiration of a key from cache
func NewMemoryWithTTL(ttl time.Duration) *MemoryCache {
	return &MemoryCache{
		items:  map[string]interface{}{},
		setAts: map[string]time.Time{},
		ttl:    ttl,
	}
}

// StartGC starts the garbage collection process in a go routine
func (r *MemoryCache) StartGC(gcInterval time.Duration) {
	r.gcInterval = gcInterval
	go func() {
		for _ = range time.Tick(gcInterval) {
			for key, _ := range r.items {
				if !r.isValid(key) {
					r.Delete(key)
				}
			}
		}
	}()
}

// Get returns a value of a given key if it exists
// and valid for the time being
func (r *MemoryCache) Get(key string) (interface{}, error) {
	r.Lock()
	defer r.Unlock()

	if !r.isValid(key) {
		r.delete(key)
		return nil, ErrNotFound
	}
	value, ok := r.items[key]
	if !ok {
		return nil, ErrNotFound
	}
	return value, nil
}

// Set will persist a value to the cache or
// override existing one with the new one
func (r *MemoryCache) Set(key string, resp interface{}) error {
	r.Lock()
	defer r.Unlock()
	r.items[key] = resp
	r.setAts[key] = time.Now()
	return nil
}

// Delete deletes a given key if exists
func (r *MemoryCache) Delete(key string) error {
	r.Lock()
	defer r.Unlock()
	r.delete(key)
	return nil
}

func (r *MemoryCache) delete(key string) {
	delete(r.items, key)
	delete(r.setAts, key)
}

func (r *MemoryCache) isValid(key string) bool {
	setAt, ok := r.setAts[key]
	if !ok {
		return false
	}

	if r.ttl == zeroTTL {
		return true
	}

	return setAt.Add(r.ttl).After(time.Now())
}
