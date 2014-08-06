package main

import (
	"fmt"
	memorycache "koding/cache/memory"
	"time"
)

func main() {
	cache := memorycache.NewMemoryCache(2 * time.Second)
	cache.StartGC(time.Millisecond * 10)
	cache.Set("test_key", "test_data")
	data, valid := cache.Get("test_key")
	if !valid {
		panic("data not found")
	}
	if data != "test_data" {
		panic("data is not \"test_data\"")
	}
	fmt.Println(data)
	time.Sleep(5 * time.Second)
	data, valid = cache.Get("test_key")
	if valid {
		panic("data found")
	}
	fmt.Println(data)
}
