package cache

// ShardedNoTS ; the concept behind this storage is that each cache entry is
// associated with a tenantID and this enables fast purging for just that
// tenantID
type ShardedNoTS struct {
	cache       map[string]Cache
	itemCount   map[string]int
	constructor func() Cache
}

// NewShardedNoTS inits ShardedNoTS struct
func NewShardedNoTS(c func() Cache) *ShardedNoTS {
	return &ShardedNoTS{
		constructor: c,
		cache:       make(map[string]Cache),
		itemCount:   make(map[string]int),
	}
}

// Get returns a value of a given key if it exists
// and valid for the time being
func (l *ShardedNoTS) Get(tenantID, key string) (interface{}, error) {
	cache, ok := l.cache[tenantID]
	if !ok {
		return nil, ErrNotFound
	}

	return cache.Get(key)
}

// Set will persist a value to the cache or override existing one with the new
// one
func (l *ShardedNoTS) Set(tenantID, key string, val interface{}) error {
	_, ok := l.cache[tenantID]
	if !ok {
		l.cache[tenantID] = l.constructor()
		l.itemCount[tenantID] = 0
	}

	l.itemCount[tenantID]++
	return l.cache[tenantID].Set(key, val)
}

// Delete deletes a given key
func (l *ShardedNoTS) Delete(tenantID, key string) error {
	_, ok := l.cache[tenantID]
	if !ok {
		return nil
	}

	l.itemCount[tenantID]--

	if l.itemCount[tenantID] == 0 {
		return l.DeleteShard(tenantID)
	}

	return l.cache[tenantID].Delete(key)
}

// DeleteShard deletes the keys inside from maps of cache & itemCount
func (l *ShardedNoTS) DeleteShard(tenantID string) error {
	delete(l.cache, tenantID)
	delete(l.itemCount, tenantID)

	return nil
}
