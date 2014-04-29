package oskite

import (
	"time"

	redigo "github.com/garyburd/redigo/redis"
	"github.com/koding/redis"
)

type redisLock struct {
	session *redis.RedisSession
	lockKey string
	timeout int
}

// newRedisLock returns a new redisLock which enables distributed lock. It
// obeys the sync.Locker interface
func (o *Oskite) newRedisLock() *redisLock {
	// oskite:production:sj:
	prefix := "oskite:" + conf.Environment + ":" + o.Region + ":"

	return &redisLock{
		session: o.RedisSession,
		lockKey: prefix + "lock_key",
		timeout: 10, // seconds
	}
}

// Lock locks r. If the lock is already in use, the calling goroutine blocks
// until the lock is available.. The lock only exists for 10 seconds to avoid
// deadlocks.
func (r *redisLock) Lock() {
	// SET lock_key "locked" EX 10 NX
	for {
		reply, err := redigo.String(r.session.Do("SET", r.lockKey, "locked", "EX", r.timeout, "NX"))
		if err == redigo.ErrNil {
			// lock is not released yet
			time.Sleep(time.Millisecond * 100)
			continue
		}

		if err != nil {
			log.Error("redis lock %v. reply: %v err: %v", r.lockKey, reply, err.Error())
			time.Sleep(time.Millisecond * 500) // penalty
			continue
		}

		break // we got out lock
	}
}

// Unlock unlocks r. Unlock can be called several times, but is should be
// associated with one Lock().
func (r *redisLock) Unlock() {
	reply, err := redigo.Int(r.session.Do("DEL", r.lockKey))
	if err != nil {
		log.Error("redis unlock %v. reply: %v err: %v", r.lockKey, reply, err.Error())
	}
}
