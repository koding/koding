package redissingleton

import (
	"koding/databases/redis"
	"koding/tools/config"
	"sync"
)

// RedisSingleton handles connection pool for Redis
type RedisSingleton struct {
	Session   *redis.RedisSession
	Err       error
	conf      *config.Config
	initMutex sync.Mutex
}

// Create a new Singleton
func New(c *config.Config) *RedisSingleton {
	return &RedisSingleton{
		conf: c,
	}
}

// Connect connects to Redis and holds the Session and Err object
// in the RedisSingleton struct
func (r *RedisSingleton) Connect() (*redis.RedisSession, error) {
	r.initMutex.Lock()
	defer r.initMutex.Unlock()

	if r.Session != nil && r.Err == nil {
		return r.Session, nil
	}

	r.Session, r.Err = redis.NewRedisSession(r.conf.Redis)
	return r.Session, r.Err
}

// Close clears the connection to redis
func (r *RedisSingleton) Close() {
	r.initMutex.Lock()
	defer r.initMutex.Unlock()

	r.Session.Close()
	r.Session = nil
	r.Err = nil
}
