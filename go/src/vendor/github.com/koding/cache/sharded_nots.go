package cache

// The concept behind this storage is that each cache entry is associated with a tenantId
// and this enables fast purging for just that tenantId
type ShardedNoTS struct {
    cache       map[string]Cache
    itemCount   map[string]int
    constructor func() Cache
}

func NewShardedNoTS(c func() Cache) *ShardedNoTS {
    return &ShardedNoTS{
        constructor: c,
        cache:       make(map[string]Cache),
        itemCount:   make(map[string]int),
    }
}

func (l *ShardedNoTS) Get(tenantId, key string) (interface{}, error) {
    cache, ok := l.cache[tenantId]
    if !ok {
        return nil, ErrNotFound
    }

    return cache.Get(key)
}

func (l *ShardedNoTS) Set(tenantId, key string, val interface{}) error {
    _, ok := l.cache[tenantId]
    if !ok {
        l.cache[tenantId] = l.constructor()
        l.itemCount[tenantId] = 0
    }

    l.itemCount[tenantId]++
    return l.cache[tenantId].Set(key, val)
}

func (l *ShardedNoTS) Delete(tenantId, key string) error {
    _, ok := l.cache[tenantId]
    if !ok {
        return nil
    }

    l.itemCount[tenantId]--

    if l.itemCount[tenantId] == 0 {
        return l.DeleteShard(tenantId)
    }

    return l.cache[tenantId].Delete(key)
}

func (l *ShardedNoTS) DeleteShard(tenantId string) error {
    delete(l.cache, tenantId)
    delete(l.itemCount, tenantId)

    return nil
}
