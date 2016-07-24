package cache

import (
	"sync"
	"time"
)

// ShardedTTL holds the required variables to compose an in memory sharded cache system
// which also provides expiring key mechanism
type ShardedTTL struct {
	// Mutex is used for handling the concurrent
	// read/write requests for cache
	sync.Mutex

	// cache holds the cache data
	cache ShardedCache

	// setAts holds the time that related item's set at, indexed by tenantId
	setAts map[string]map[string]time.Time

	// ttl is a duration for a cache key to expire
	ttl time.Duration

	// gcInterval is a duration for garbage collection
	gcInterval time.Duration
}

// NewShardedCacheWithTTL creates a sharded cache system with TTL based on specified Cache constructor
// Which everytime will return the true values about a cache hit
// and never will leak memory
// ttl is used for expiration of a key from cache
func NewShardedCacheWithTTL(ttl time.Duration, f func() Cache) *ShardedTTL {
	return &ShardedTTL{
		cache:  NewShardedNoTS(f),
		setAts: map[string]map[string]time.Time{},
		ttl:    ttl,
	}
}

// NewShardedWithTTL creates an in-memory sharded cache system
// ttl is used for expiration of a key from cache
func NewShardedWithTTL(ttl time.Duration) *ShardedTTL {
	return NewShardedCacheWithTTL(ttl, NewMemNoTSCache)
}



// StartGC starts the garbage collection process in a go routine
func (r *ShardedTTL) StartGC(gcInterval time.Duration) {
	r.gcInterval = gcInterval
	go func() {
		for _ = range time.Tick(gcInterval) {
			r.Lock()
			for tenantId := range r.setAts {
				for key := range r.setAts[tenantId] {
					if !r.isValid(tenantId, key) {
						r.delete(tenantId, key)
					}
				}
			}
			r.Unlock()
		}
	}()
}

// Get returns a value of a given key if it exists
// and valid for the time being
func (r *ShardedTTL) Get(tenantId, key string) (interface{}, error) {
	r.Lock()
	defer r.Unlock()

	if !r.isValid(tenantId, key) {
		r.delete(tenantId, key)
		return nil, ErrNotFound
	}

	value, err := r.cache.Get(tenantId, key)
	if err != nil {
		return nil, err
	}

	return value, nil
}

// Set will persist a value to the cache or
// override existing one with the new one
func (r *ShardedTTL) Set(tenantId, key string, value interface{}) error {
	r.Lock()
	defer r.Unlock()

	r.cache.Set(tenantId, key, value)
	_, ok := r.setAts[tenantId]
	if !ok {
		r.setAts[tenantId] = make(map[string]time.Time)
	}
	r.setAts[tenantId][key] = time.Now()
	return nil
}

// Delete deletes a given key if exists
func (r *ShardedTTL) Delete(tenantId, key string) error {
	r.Lock()
	defer r.Unlock()

	r.delete(tenantId, key)
	return nil
}

func (r *ShardedTTL) delete(tenantId, key string) {
	_, ok := r.setAts[tenantId]
	if !ok {
		return
	}
	r.cache.Delete(tenantId, key)
	delete(r.setAts[tenantId], key)
	if len(r.setAts[tenantId]) == 0 {
		delete(r.setAts, tenantId)
	}
}

func (r *ShardedTTL) isValid(tenantId, key string) bool {

	_, ok := r.setAts[tenantId]
	if !ok {
		return false
	}
	setAt, ok := r.setAts[tenantId][key]
	if !ok {
		return false
	}
	if r.ttl == zeroTTL {
		return true
	}

	return setAt.Add(r.ttl).After(time.Now())
}

func (r *ShardedTTL) DeleteShard(tenantId string) error {
	r.Lock()
	defer r.Unlock()

	_, ok := r.setAts[tenantId]
	if ok {
		for key := range r.setAts[tenantId] {
			r.delete(tenantId, key)
		}
	}
	return nil
}
