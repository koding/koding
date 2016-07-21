package cache

import (
	"testing"
	"time"
)

func TestShardedCacheGetSet(t *testing.T) {
	cache := NewShardedWithTTL(2 * time.Second)
	cache.StartGC(time.Millisecond * 10)
	cache.Set("user1", "test_key", "test_data")
	data, err := cache.Get("user1", "test_key")
	if err != nil {
		t.Fatal("data not found")
	}
	if data != "test_data" {
		t.Fatal("data is not \"test_data\"")
	}
}

func TestShardedCacheTTL(t *testing.T) {
	cache := NewShardedWithTTL(100 * time.Millisecond)
	cache.StartGC(time.Millisecond * 10)
	cache.Set("user1", "test_key", "test_data")
	time.Sleep(200 * time.Millisecond)
	_, err := cache.Get("user1", "test_key")
	if err == nil {
		t.Fatal("data found")
	}
}

func TestShardedCacheTTLNilValue(t *testing.T) {
	cache := NewShardedWithTTL(100 * time.Millisecond)
	cache.StartGC(time.Millisecond * 10)
	cache.Set("user1", "test_key", nil)
	data, err := cache.Get("user1", "test_key")
	if err != nil {
		t.Fatal("data found")
	}
	if data != nil {
		t.Fatal("data is not null")
	}
}

func TestShardedCacheTTLDeleteShard(t *testing.T) {
	cache := NewShardedWithTTL(100 * time.Millisecond)
	cache.StartGC(time.Millisecond * 10)
	cache.Set("user1", "test_key", nil)
	cache.DeleteShard("user1")
	_, err := cache.Get("user1", "test_key")
	if err == nil {
		t.Fatal("data found")
	}
}
