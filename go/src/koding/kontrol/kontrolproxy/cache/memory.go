package cache

import (
	"sync"
)

type MemoryCache struct {
	sync.Mutex
	items map[string][]byte
}

func NewMemoryCache() *MemoryCache {
	return &MemoryCache{
		items: map[string][]byte{},
	}
}

func (c *MemoryCache) Get(key string) ([]byte, bool) {
	c.Lock()
	defer c.Unlock()

	value, ok := c.items[key]
	return value, ok
}

func (c *MemoryCache) Set(key string, resp []byte) {
	c.Lock()
	defer c.Unlock()

	c.items[key] = resp
}

func (c *MemoryCache) Delete(key string) {
	c.Lock()
	defer c.Unlock()

	delete(c.items, key)
}
