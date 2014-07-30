package cache

import (
	"testing"
	"time"
)

func TestMemoryCacheGetSet(t *testing.T) {
	cache := NewMemoryWithTTL(2 * time.Second)
	cache.StartGC(time.Millisecond * 10)
	cache.Set("test_key", "test_data")
	data, err := cache.Get("test_key")
	if err != nil {
		t.Fatal("data not found")
	}
	if data != "test_data" {
		t.Fatal("data is not \"test_data\"")
	}
}

func TestMemoryCacheTTL(t *testing.T) {
	cache := NewMemoryWithTTL(2 * time.Second)
	cache.StartGC(time.Millisecond * 10)
	cache.Set("test_key", "test_data")
	time.Sleep(2 * time.Second)
	_, err := cache.Get("test_key")
	if err == nil {
		t.Fatal("data found")
	}
}

func TestMemoryCache0TTL(t *testing.T) {
	cache := NewMemory()
	cache.Set("test_key", "test_data")
	time.Sleep(1 * time.Second)
	_, err := cache.Get("test_key")
	if err != nil {
		t.Fatal("data found")
	}
}
