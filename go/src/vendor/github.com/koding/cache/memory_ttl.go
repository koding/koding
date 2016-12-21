package cache

import (
	"sync"
	"time"
)

var zeroTTL = time.Duration(0)

// MemoryTTL holds the required variables to compose an in memory cache system
// which also provides expiring key mechanism
type MemoryTTL struct {
	// Mutex is used for handling the concurrent
	// read/write requests for cache
	sync.RWMutex

	// cache holds the cache data
	cache *MemoryNoTS

	// setAts holds the time that related item's set at
	setAts map[string]time.Time

	// ttl is a duration for a cache key to expire
	ttl time.Duration

	// gcTicker controls gc intervals
	gcTicker *time.Ticker

	// done controls sweeping goroutine lifetime
	done chan struct{}
}

// NewMemoryWithTTL creates an inmemory cache system
// Which everytime will return the true values about a cache hit
// and never will leak memory
// ttl is used for expiration of a key from cache
func NewMemoryWithTTL(ttl time.Duration) *MemoryTTL {
	return &MemoryTTL{
		cache:  NewMemoryNoTS(),
		setAts: map[string]time.Time{},
		ttl:    ttl,
	}
}

// StartGC starts the garbage collection process in a go routine
func (r *MemoryTTL) StartGC(gcInterval time.Duration) {
	if gcInterval <= 0 {
		return
	}

	ticker := time.NewTicker(gcInterval)
	done := make(chan struct{})

	r.Lock()
	r.gcTicker = ticker
	r.done = done
	r.Unlock()

	go func() {
		for {
			select {
			case <-ticker.C:
				now := time.Now()

				r.Lock()
				for key := range r.cache.items {
					if !r.isValidTime(key, now) {
						r.delete(key)
					}
				}
				r.Unlock()
			case <-done:
				return
			}
		}
	}()
}

// StopGC stops sweeping goroutine.
func (r *MemoryTTL) StopGC() {
	if r.gcTicker != nil {
		r.Lock()
		r.gcTicker.Stop()
		r.gcTicker = nil
		close(r.done)
		r.done = nil
		r.Unlock()
	}
}

// Get returns a value of a given key if it exists
// and valid for the time being
func (r *MemoryTTL) Get(key string) (interface{}, error) {
	r.RLock()

	for !r.isValid(key) {
		r.RUnlock()
		// Need write lock to delete key, so need to unlock, relock and recheck
		r.Lock()
		if !r.isValid(key) {
			r.delete(key)
			r.Unlock()
			return nil, ErrNotFound
		}
		r.Unlock()
		// Could become invalid again in this window
		r.RLock()
	}

	defer r.RUnlock()

	value, err := r.cache.Get(key)
	if err != nil {
		return nil, err
	}

	return value, nil
}

// Set will persist a value to the cache or
// override existing one with the new one
func (r *MemoryTTL) Set(key string, value interface{}) error {
	r.Lock()
	defer r.Unlock()

	r.cache.Set(key, value)
	r.setAts[key] = time.Now()
	return nil
}

// Delete deletes a given key if exists
func (r *MemoryTTL) Delete(key string) error {
	r.Lock()
	defer r.Unlock()

	r.delete(key)
	return nil
}

func (r *MemoryTTL) delete(key string) {
	r.cache.Delete(key)
	delete(r.setAts, key)
}

func (r *MemoryTTL) isValid(key string) bool {
	return r.isValidTime(key, time.Now())
}

func (r *MemoryTTL) isValidTime(key string, t time.Time) bool {
	setAt, ok := r.setAts[key]
	if !ok {
		return false
	}

	if r.ttl == zeroTTL {
		return true
	}

	return setAt.Add(r.ttl).After(t)
}
