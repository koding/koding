package cache

import "testing"

func TestShardedCacheNoTSGetSet(t *testing.T) {
	cache := NewShardedNoTS(NewMemNoTSCache)
	testShardedCacheGetSet(t, cache)
}

func TestShardedCacheNoTSDelete(t *testing.T) {
	cache := NewShardedNoTS(NewMemNoTSCache)
	testShardedCacheDelete(t, cache)
}

func TestShardedCacheNoTSNilValue(t *testing.T) {
	cache := NewShardedNoTS(NewMemNoTSCache)
	testShardedCacheNilValue(t, cache)
}

func TestShardedCacheNoTSDeleteShard(t *testing.T) {
	cache := NewShardedNoTS(NewMemNoTSCache)
	testDeleteShard(t, cache)
}
