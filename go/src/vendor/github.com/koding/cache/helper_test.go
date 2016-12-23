package cache

import "testing"

func testCacheGetSet(t *testing.T, cache Cache) {
	err := cache.Set("test_key", "test_data")
	if err != nil {
		t.Fatal("should not give err while setting item")
	}

	err = cache.Set("test_key2", "test_data2")
	if err != nil {
		t.Fatal("should not give err while setting item")
	}

	data, err := cache.Get("test_key")
	if err != nil {
		t.Fatal("test_key should be in the cache")
	}

	if data != "test_data" {
		t.Fatal("data is not \"test_data\"")
	}

	data, err = cache.Get("test_key2")
	if err != nil {
		t.Fatal("test_key2 should be in the cache")
	}

	if data != "test_data2" {
		t.Fatal("data is not \"test_data2\"")
	}
}

func testCacheNilValue(t *testing.T, cache Cache) {
	err := cache.Set("test_key", nil)
	if err != nil {
		t.Fatal("should not give err while setting item")
	}

	data, err := cache.Get("test_key")
	if err != nil {
		t.Fatal("test_key should be in the cache")
	}

	if data != nil {
		t.Fatal("data is not nil")
	}

	err = cache.Delete("test_key")
	if err != nil {
		t.Fatal("should not give err while deleting item")
	}

	_, err = cache.Get("test_key")
	if err == nil {
		t.Fatal("test_key should not be in the cache")
	}
}

func testCacheDelete(t *testing.T, cache Cache) {
	cache.Set("test_key", "test_data")
	cache.Set("test_key2", "test_data2")

	err := cache.Delete("test_key3")
	if err != nil {
		t.Fatal("non-exiting item should not give error")
	}

	err = cache.Delete("test_key")
	if err != nil {
		t.Fatal("exiting item should not give error")
	}

	data, err := cache.Get("test_key")
	if err != ErrNotFound {
		t.Fatal("test_key should not be in the cache")
	}

	if data != nil {
		t.Fatal("data should be nil")
	}
}

func testShardedCacheGetSet(t *testing.T, cache ShardedCache) {
	err := cache.Set("user1", "test_key", "test_data")
	if err != nil {
		t.Fatal("should not give err while setting item")
	}

	err = cache.Set("user1", "test_key2", "test_data2")
	if err != nil {
		t.Fatal("should not give err while setting item")
	}

	err = cache.Set("user2", "test_key3", "test_data3")
	if err != nil {
		t.Fatal("should not give err while setting item")
	}

	data, err := cache.Get("user1", "test_key")
	if err != nil {
		t.Fatal("test_key should be in the cache")
	}

	if data != "test_data" {
		t.Fatal("data is not \"test_data\"")
	}

	data, err = cache.Get("user1", "test_key2")
	if err != nil {
		t.Fatal("test_key2 should be in the cache")
	}

	if data != "test_data2" {
		t.Fatal("data is not \"test_data2\"")
	}

	data, err = cache.Get("user2", "test_key3")
	if err != nil {
		t.Fatal("test_key3 should be in the cache")
	}

	if data != "test_data3" {
		t.Fatal("data is not \"test_data3\"")
	}
}

func testShardedCacheNilValue(t *testing.T, cache ShardedCache) {
	err := cache.Set("user1", "test_key", nil)
	if err != nil {
		t.Fatal("should not give err while setting item")
	}

	data, err := cache.Get("user1", "test_key")
	if err != nil {
		t.Fatal("test_key should be in the cache")
	}

	if data != nil {
		t.Fatal("data is not nil")
	}

	err = cache.Delete("user1", "test_key")
	if err != nil {
		t.Fatal("should not give err while deleting item")
	}

	_, err = cache.Get("user1", "test_key")
	if err == nil {
		t.Fatal("test_key should not be in the cache")
	}
}

func testShardedCacheDelete(t *testing.T, cache ShardedCache) {
	cache.Set("user1", "test_key", "test_data")
	cache.Set("user1", "test_key2", "test_data2")

	err := cache.Delete("user1", "test_key3")
	if err != nil {
		t.Fatal("non-exiting item should not give error")
	}
	err = cache.Delete("user2", "test_key3")
	if err != nil {
		t.Fatal("non-exiting shard should not give error")
	}

	err = cache.Delete("user1", "test_key")
	if err != nil {
		t.Fatal("exiting item should not give error")
	}

	data, err := cache.Get("user1", "test_key")
	if err != ErrNotFound {
		t.Fatal("test_key should not be in the cache")
	}

	if data != nil {
		t.Fatal("data should be nil")
	}
}

func testDeleteShard(t *testing.T, cache ShardedCache) {
	cache.Set("user1", "test_key", "test_data")
	cache.Set("user1", "test_key2", "test_data2")
	cache.Set("user2", "test_key", "test_data")

	err := cache.DeleteShard("user1")
	if err != nil {
		t.Fatal("exiting shard should not give error")
	}

	err = cache.DeleteShard("user3")
	if err != nil {
		t.Fatal("non-exiting shard should not give error")
	}

	data, err := cache.Get("user1", "test_key")
	if err != ErrNotFound {
		t.Fatal("test_key should not be in the cache")
	}

	if data != nil {
		t.Fatal("data should be nil")
	}

	_, err = cache.Get("user2", "test_key")
	if err == ErrNotFound {
		t.Fatal("test_key for user2 should still be in cache")
	}
}
