package memory

import (
	"sync"
	"time"
)

type MemoryCache struct {
	sync.RWMutex
	items  map[string]interface{}
	setAts map[string]time.Time
	ttl    time.Duration
}

func NewMemoryCache(ttl, gcInterval time.Duration) *MemoryCache {

	memoryCache := &MemoryCache{
		items:  map[string]interface{}{},
		setAts: map[string]time.Time{},
		ttl:    ttl,
	}

	go func(memoryCache *MemoryCache) {
		for _ = range time.Tick(gcInterval) {
			for key, _ := range memoryCache.items {
				if !memoryCache.isValid(key) {
					memoryCache.Delete(key)
				}
			}
		}
	}(memoryCache)

	return memoryCache
}

func (r *MemoryCache) Get(key string) (interface{}, bool) {
	r.RLock()
	defer r.RUnlock()

	if !r.isValid(key) {
		r.delete(key)
		return nil, false
	}
	value, ok := r.items[key]
	return value, ok
}

func (r *MemoryCache) Set(key string, resp interface{}) {
	r.Lock()
	defer r.Unlock()
	r.items[key] = resp
	r.setAts[key] = time.Now()
}

func (r *MemoryCache) Delete(key string) {
	r.Lock()
	defer r.Unlock()
	r.delete(key)
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
	return setAt.Add(r.ttl).After(time.Now())
}
