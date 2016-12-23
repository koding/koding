package cache

import (
	"fmt"
	"sync"
	"time"

	mgo "gopkg.in/mgo.v2"
)

const (
	defaultExpireDuration = time.Minute
	defaultCollectionName = "jCache"
	defaultGCInterval     = time.Minute
	indexExpireAt         = "expireAt"
)

// MongoCache holds the cache values that will be stored in mongoDB
type MongoCache struct {
	// mongeSession specifies the mongoDB connection
	mongeSession *mgo.Session

	// CollectionName speficies the optional collection name for mongoDB
	// if CollectionName is not set, then default value will be set
	CollectionName string

	// ttl is a duration for a cache key to expire
	TTL time.Duration

	// GCInterval specifies the time duration for garbage collector time interval
	GCInterval time.Duration

	// GCStart starts the garbage collector and deletes the
	// expired keys from mongo with given time interval
	GCStart bool

	// gcTicker controls gc intervals
	gcTicker *time.Ticker

	// done controls sweeping goroutine lifetime
	done chan struct{}

	// Mutex is used for handling the concurrent
	// read/write requests for cache
	sync.RWMutex
}

// Option sets the options specified.
type Option func(*MongoCache)

// NewMongoCacheWithTTL creates a caching layer backed by mongo. TTL's are
// managed either by a background cleaner or document is removed on the Get
// operation. Mongo TTL indexes are not utilized since there can be multiple
// systems using the same collection with different TTL values.
//
// The responsibility of stopping the GC process belongs to the user.
//
// Session is not closed while stopping the GC.
//
// This self-referential function satisfy you to avoid passing
// nil value to the function as parameter
// e.g (usage) :
// configure with defaults, just call;
// NewMongoCacheWithTTL(session)
//
// configure ttl duration with;
// NewMongoCacheWithTTL(session, func(m *MongoCache) {
// 		m.TTL = 2 * time.Minute
// })
// or
// NewMongoCacheWithTTL(session, SetTTL(time.Minute * 2))
//
// configure collection name with;
// NewMongoCacheWithTTL(session, func(m *MongoCache) {
// 		m.CollectionName = "MongoCacheCollectionName"
// })
func NewMongoCacheWithTTL(session *mgo.Session, configs ...Option) *MongoCache {
	if session == nil {
		panic("session must be set")
	}

	mc := &MongoCache{
		mongeSession:   session,
		TTL:            defaultExpireDuration,
		CollectionName: defaultCollectionName,
		GCInterval:     defaultGCInterval,
		GCStart:        false,
	}

	for _, configFunc := range configs {
		configFunc(mc)
	}

	if mc.GCStart {
		mc.StartGC(mc.GCInterval)
	}

	return mc
}

// MustEnsureIndexExpireAt ensures the expireAt index
// usage:
// NewMongoCacheWithTTL(mongoSession, MustEnsureIndexExpireAt())
func MustEnsureIndexExpireAt() Option {
	return func(m *MongoCache) {
		if err := m.EnsureIndex(); err != nil {
			panic(fmt.Sprintf("index must ensure %q", err))
		}
	}
}

// StartGC enables the garbage collector in MongoCache struct
// usage:
// NewMongoCacheWithTTL(mongoSession, StartGC())
func StartGC() Option {
	return func(m *MongoCache) {
		m.GCStart = true
	}
}

// SetTTL sets the ttl duration in MongoCache as option
// usage:
// NewMongoCacheWithTTL(mongoSession, SetTTL(time*Minute))
func SetTTL(duration time.Duration) Option {
	return func(m *MongoCache) {
		m.TTL = duration
	}
}

// SetGCInterval sets the garbage collector interval in MongoCache struct as option
// usage:
// NewMongoCacheWithTTL(mongoSession, SetGCInterval(time*Minute))
func SetGCInterval(duration time.Duration) Option {
	return func(m *MongoCache) {
		m.GCInterval = duration
	}
}

// SetCollectionName sets the collection name for mongoDB in MongoCache struct as option
// usage:
// NewMongoCacheWithTTL(mongoSession, SetCollectionName("mongoCollName"))
func SetCollectionName(collName string) Option {
	return func(m *MongoCache) {
		m.CollectionName = collName
	}
}

// Get returns a value of a given key if it exists
func (m *MongoCache) Get(key string) (interface{}, error) {
	data, err := m.get(key)
	if err == mgo.ErrNotFound {
		return nil, ErrNotFound
	}

	if err != nil {
		return nil, err
	}

	return data.Value, nil
}

// Set will persist a value to the cache or override existing one with the new
// one
func (m *MongoCache) Set(key string, value interface{}) error {
	return m.set(key, m.TTL, value)
}

// SetEx will persist a value to the cache or override existing one with the new
// one with ttl duration
func (m *MongoCache) SetEx(key string, duration time.Duration, value interface{}) error {
	return m.set(key, duration, value)
}

// Delete deletes a given key if exists
func (m *MongoCache) Delete(key string) error {
	return m.delete(key)
}

// EnsureIndex ensures the index with expireAt key
func (m *MongoCache) EnsureIndex() error {
	query := func(c *mgo.Collection) error {
		return c.EnsureIndexKey(indexExpireAt)
	}

	return m.run(m.CollectionName, query)
}

// StartGC starts the garbage collector with given time interval The
// expired data will be checked & deleted with given interval time
func (m *MongoCache) StartGC(gcInterval time.Duration) {
	if gcInterval <= 0 {
		return
	}

	ticker := time.NewTicker(gcInterval)
	done := make(chan struct{})

	m.Lock()
	m.gcTicker = ticker
	m.done = done
	m.Unlock()

	go func() {
		for {
			select {
			case <-ticker.C:
				m.Lock()
				m.deleteExpiredKeys()
				m.Unlock()
			case <-done:
				return
			}
		}
	}()
}

// StopGC stops sweeping goroutine.
func (m *MongoCache) StopGC() {
	if m.gcTicker != nil {
		m.Lock()
		m.gcTicker.Stop()
		m.gcTicker = nil
		close(m.done)
		m.done = nil
		m.Unlock()
	}
}
