package redis

import "sync"

// SingletonSession handles connection pool for Redis
type SingletonSession struct {
	Session   *RedisSession
	Err       error
	server    string
	initMutex sync.Mutex
}

// Create a new Singleton
func Singleton(server string) *SingletonSession {
	return &SingletonSession{
		server: server,
	}
}

// Connect connects to Redis and holds the Session and Err object
// in the SingletonSession struct
func (r *SingletonSession) Connect() (*RedisSession, error) {
	r.initMutex.Lock()
	defer r.initMutex.Unlock()

	if r.Session != nil && r.Err == nil {
		return r.Session, nil
	}

	r.Session, r.Err = NewRedisSession(&RedisConf{Server: r.server})
	return r.Session, r.Err
}

// Close clears the connection to redis
func (r *SingletonSession) Close() {
	r.initMutex.Lock()
	defer r.initMutex.Unlock()

	r.Session.Close()
	r.Session = nil
	r.Err = nil
}
