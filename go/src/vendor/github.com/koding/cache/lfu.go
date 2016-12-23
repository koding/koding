package cache

import "sync"

// LFU holds the Least frequently used cache values
type LFU struct {
	// Mutex is used for handling the concurrent
	// read/write requests for cache
	sync.Mutex

	// cache holds the all cache values
	cache Cache
}

// NewLFU creates a thread-safe LFU cache
func NewLFU(size int) Cache {
	return &LRU{
		cache: NewLFUNoTS(size),
	}
}

// Get returns the value of a given key if it exists, every get item will be
// increased for every usage
func (l *LFU) Get(key string) (interface{}, error) {
	l.Lock()
	defer l.Unlock()

	return l.cache.Get(key)
}

// Set sets or overrides the given key with the given value, every set item will
// be increased as usage.
// when the cache is full, least frequently used items will be evicted from
// linked list
func (l *LFU) Set(key string, val interface{}) error {
	l.Lock()
	defer l.Unlock()

	return l.cache.Set(key, val)
}

// Delete deletes the given key-value pair from cache, this function doesnt
// return an error if item is not in the cache
func (l *LFU) Delete(key string) error {
	l.Lock()
	defer l.Unlock()

	return l.cache.Delete(key)
}
