# Cache [![GoDoc](https://godoc.org/github.com/koding/cache?status.svg)](https://godoc.org/github.com/koding/cache) [![Build Status](https://travis-ci.org/koding/cache.svg?branch=master)](https://travis-ci.org/koding/cache)


Cache is a backend provider for common use cases

## Install and Usage

Install the package with:

```bash
go get github.com/koding/cache
```

Import it with:

```go
import "github.com/koding/cache"
```


Example
```go

// create a cache with 2 second TTL
cache := NewMemoryWithTTL(2 * time.Second)
// start garbage collection for expired keys
cache.StartGC(time.Millisecond * 10)
// set item
err := cache.Set("test_key", "test_data")
// get item
data, err := cache.Get("test_key")
```


## Supported caching algorithms:

- MemoryNoTS  : provides a non-thread safe in-memory caching system
- Memory      : provides a thread safe in-memory caching system, built on top of MemoryNoTS cache
- LRUNoTS     : provides a non-thread safe, fixed size in-memory caching system, built on top of MemoryNoTS cache
- LRU         : provides a thread safe, fixed size in-memory caching system, built on top of LRUNoTS cache
- MemoryTTL   : provides a thread safe, expiring in-memory caching system,  built on top of MemoryNoTS cache
- ShardedNoTS : provides a non-thread safe sharded cache system, built on top of a cache interface
- ShardedTTL  : provides a thread safe, expiring in-memory sharded cache system, built on top of ShardedNoTS over MemoryNoTS
- LFUNoTS     : provides a non-thread safe, fixed size in-memory caching system, built on top of MemoryNoTS cache
- LFU         : provides a thread safe, fixed size in-memory caching system, built on top of LFUNoTS cache
