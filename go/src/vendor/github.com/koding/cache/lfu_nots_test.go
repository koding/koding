package cache

import "testing"

func TestLFUNoTSGetSet(t *testing.T) {
	cache := NewLFUNoTS(2)
	testCacheGetSet(t, cache)
}

func TestLFUNoTSUsageWithSet(t *testing.T) {
	cache := NewLFUNoTS(2)
	cache.Set("test_key1", "test_data")
	cache.Set("test_key2", "test_data2")
	cache.Set("test_key2", "test_data2")
	cache.Set("test_key3", "test_data3")
	cache.Set("test_key3", "test_data3")
	cache.Set("test_key3", "test_data3")

	// test_key3 is used 3 times
	// test_key2 is used 2 times
	// test_key1 is used 1 times
	_, err := cache.Get("test_key1")
	if err != ErrNotFound {
		t.Fatal("test_key1 should not be in the cache")
	}
	data, err := cache.Get("test_key2")
	if err != nil {
		t.Fatal("test_key2 should be in the cache")
	}

	if data != "test_data2" {
		t.Fatal("data should be equal test_data2")
	}

	data, err = cache.Get("test_key3")
	if err != nil {
		t.Fatal("test_key3 should be in the cache")
	}

	if data != "test_data3" {
		t.Fatal("data should be equal test_data3")
	}
}

func TestLFUNoTSUsageWithSetAndGet(t *testing.T) {
	cache := NewLFUNoTS(3)
	cache.Set("test_key1", "test_data1")
	cache.Set("test_key2", "test_data2")
	cache.Set("test_key3", "test_data3")

	_, err := cache.Get("test_key1")
	if err != nil {
		t.Fatal("test_key1 should not in the cache")
	}
	_, err = cache.Get("test_key2")
	if err != nil {
		t.Fatal("test_key2 should not in the cache")
	}
	_, err = cache.Get("test_key2")
	if err != nil {
		t.Fatal("test_key2 should be in the cache")
	}
	_, err = cache.Get("test_key3")
	if err != nil {
		t.Fatal("test_key3 should be in the cache")
	}
	_, err = cache.Get("test_key3")
	if err != nil {
		t.Fatal("test_key3 should be in the cache")
	}
	_, err = cache.Get("test_key3")
	if err != nil {
		t.Fatal("test_key3 should be in the cache")
	}
	// set test_key4 into cache list
	// test_key1 should not be in cache list
	if err = cache.Set("test_key4", "test_data4"); err != nil {
		t.Fatal("test_key4 should be set")
	}

	_, err = cache.Get("test_key1")
	if err != ErrNotFound {
		t.Fatal("test_key1 should not be in the cache")
	}

	data, err := cache.Get("test_key4")
	if err != nil {
		t.Fatal("test_key4 should be in the cache")
	}

	if data != "test_data4" {
		t.Fatal("data should be equal to test_data4")
	}
}

func TestLFUNoTSDelete(t *testing.T) {
	cache := NewLFUNoTS(3)
	cache.Set("test_key1", "test_data1")
	cache.Set("test_key2", "test_data2")
	cache.Set("test_key3", "test_data3")
	_, err := cache.Get("test_key1")
	if err != nil {
		t.Fatal("test_key1 should be in the cache")
	}
	_, err = cache.Get("test_key2")
	if err != nil {
		t.Fatal("test_key2 should be in the cache")
	}
	_, err = cache.Get("test_key3")
	if err != nil {
		t.Fatal("test_key3 should be in the cache")
	}
	if err = cache.Delete("test_key1"); err != nil {
		t.Fatal("test_key1 should be deleted")
	}

	_, err = cache.Get("test_key1")
	if err != ErrNotFound {
		t.Fatal("test_key1 should not be in the cache")
	}
}
