package oskite

import (
	"fmt"
	"strings"
	"sync"
	"time"

	redigo "github.com/garyburd/redigo/redis"
	"github.com/hashicorp/go-version"
	"github.com/koding/redis"
)

var (
	dlocks   = make(map[string]sync.Locker)
	dlocksMu sync.Mutex
)

// emptyLock is used for mocking up an sync.Locker. It doesn't do anything and
// is used only for placeholder.
type emptyLock struct{}

type redisLock struct {
	session *redis.RedisSession
	lockKey string
	timeout float64
	sleep   time.Duration
}

// newDlock returns a distributed lock
func (o *Oskite) newDlock(key string, sleep, timeout time.Duration) sync.Locker {
	if dlockSupported {
		return o.newRedisLock(key, sleep, timeout)
	}

	return &emptyLock{}
}

func (e *emptyLock) Lock()   {}
func (e *emptyLock) Unlock() {}

// newRedisLock returns a new redisLock which enables distributed lock. It
// implies the sync.Locker interface.  timeout indicates a maximum life for the
// lock. sleep indicates the amount of time to sleep per loop iteration when
// the lock is in blocking mode and another client is currently holding the
// lock.
func (o *Oskite) newRedisLock(keyName string, sleep, timeout time.Duration) *redisLock {
	// oskite:production:sj:
	prefix := "oskite:" + conf.Environment + ":" + o.Region + ":"

	return &redisLock{
		session: o.RedisSession,
		lockKey: prefix + "lock_key_" + keyName,
		timeout: timeout.Seconds(), // seconds
		sleep:   sleep,
	}
}

// Lock locks r. If the lock is already in use, the calling goroutine blocks
// until the lock is available.
func (r *redisLock) Lock() {
	penaltyCount := 0

	for {
		// redis equilevant: SET lock_key "locked" EX 10 NX
		reply, err := redigo.String(r.session.Do("SET", r.lockKey, "locked", "EX", r.timeout, "NX"))
		if err == nil {
			break // we got our lock
		}

		// lock is not released yet, try again until we got one
		if err == redigo.ErrNil {
			time.Sleep(r.sleep)
			continue
		}

		// something is wrong with lock acquiring
		log.Error("redis lock %v. reply: %v err: %v", r.lockKey, reply, err.Error())

		penaltyCount++
		if penaltyCount == 10 {
			log.Error("redis lock penalty breaking %v", r.lockKey)
			break
		}

		time.Sleep(time.Second) // penalty
		continue
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

// redisVersion returns back the current used redis version
func (o *Oskite) redisVersion() string {
	replies, err := redigo.String(o.RedisSession.Do("INFO", "server"))
	if err != nil {
		log.Error("redis version err: %v", err.Error())
	}

	values := strings.Split(replies, "\n")

	for _, v := range values {
		if !strings.HasPrefix(v, "redis_version") {
			continue
		}

		version := strings.Split(v, ":")
		return strings.TrimSpace(version[1])
	}

	return ""
}

func checkRedisVersion(v string) bool {
	required, err := version.NewVersion("2.6.12")
	if err != nil {
		fmt.Println("checkRedisVersion err", err)
		return false
	}

	current, err := version.NewVersion(v)
	if err != nil {
		fmt.Println("checkRedisVersion err", err)
		return false
	}

	return current.GreaterThan(required)
}
