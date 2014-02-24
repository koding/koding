package redis

import (
	"errors"
	"fmt"
	"strconv"
	"time"

	"github.com/garyburd/redigo/redis"
)

type RedisSession struct {
	pool   *redis.Pool
	prefix string
}

func NewRedisSession(server string) (*RedisSession, error) {
	s := &RedisSession{}

	pool := &redis.Pool{
		MaxIdle:     3,
		IdleTimeout: 240 * time.Second,
		Dial: func() (redis.Conn, error) {
			c, err := redis.Dial("tcp", server)
			if err != nil {
				return nil, err
			}
			return c, err
		},
	}
	s.pool = pool
	// when we use connection pooling
	// dialing and returning an error will be
	// with the request
	return s, nil
}

// SetPrefix is used to add a prefix to all keys to be used. It is useful for
// creating namespaces for each different application
func (r *RedisSession) SetPrefix(name string) {
	r.prefix = name + ":"
}

func (r *RedisSession) addPrefix(name string) string {
	return r.prefix + name
}

// Do is a wrapper around redigo's redis.Do method that executes any redis
// command. Do does not support prefix support. Example usage: redis.Do("INCR",
// "counter").
func (r *RedisSession) Do(cmd string, args ...interface{}) (interface{}, error) {
	conn := r.pool.Get()
	// conn.Close() returns an error but we are allready returning regarding error
	// while returning the Do(..) response
	defer conn.Close()
	return conn.Do(cmd, args...)
}

// Send is a wrapper around redigo's redis.Send method that writes the
// command to the client's output buffer.
func (r *RedisSession) Send(cmd string, args ...interface{}) error {
	conn := r.pool.Get()
	// conn.Close() returns an error but we are allready returning regarding error
	// while returning the Do(..) response
	defer conn.Close()
	return conn.Send(cmd, args...)
}

// Set is used to hold the string value. If key already holds a value, it is
// overwritten, regardless of its type. A return of nil means successfull.
// Example usage: redis.Set("arslan:name", "fatih")
func (r *RedisSession) Set(key, value string) error {
	reply, err := r.Do("SET", r.addPrefix(key), value)
	if err != nil {
		return err
	}

	if reply != "OK" {
		return fmt.Errorf("reply string is wrong!: %s", reply)

	}
	return nil
}

// Get is used to get the value of key. If the key does not exist an empty
// string is returned. Usage: redis.Get("arslan")
func (r *RedisSession) Get(key string) (string, error) {
	reply, err := redis.String(r.Do("GET", r.addPrefix(key)))
	if err != nil {
		return "", err
	}
	return reply, nil
}

// GetInt is used the value of key as an integer. If the key does not exist or
// the stored value is a non-integer, zero is returned. Example usage:
// redis.GetInt("counter")
func (r *RedisSession) GetInt(key string) (int, error) {
	reply, err := redis.Int(r.Do("GET", r.addPrefix(key)))
	if err != nil {
		return 0, err
	}

	return reply, nil
}

// Del is used to remove the specified keys. Key is ignored if it does not
// exist. It returns the number of keys that were removed. Example usage:
// redis.Del("counter", "arslan:name")
func (r *RedisSession) Del(args ...interface{}) (int, error) {
	prefixed := make([]interface{}, 0)
	for _, arg := range args {
		prefixed = append(prefixed, r.addPrefix(arg.(string)))
	}

	reply, err := redis.Int(r.Do("DEL", prefixed...))
	if err != nil {
		return 0, err
	}
	return reply, nil
}

// Incr increments the number stored at key by one. If the key does not exist,
// it is set to 0 before performing the operation. An error is returned if the
// key contains a value of the wrong type or contains a string that can not be
// represented as integer
func (r *RedisSession) Incr(key string) (int, error) {
	reply, err := redis.Int(r.Do("INCR", r.addPrefix(key)))
	if err != nil {
		return 0, err
	}

	return reply, nil
}

// Expire sets a timeout on a key. After the timeout has expired, the key will
// automatically be deleted. Calling Expire on a key that has already expire
// set will update the expire value.
func (r *RedisSession) Expire(key string, timeout time.Duration) error {
	seconds := strconv.Itoa(int(timeout.Seconds()))
	reply, err := redis.Int(r.Do("EXPIRE", r.addPrefix(key), seconds))
	if err != nil {
		return err
	}

	if reply != 1 {
		return errors.New("key does not exist or the timeout could not be set")
	}

	return nil
}

// Exists returns true if key exists or false if not.
func (r *RedisSession) Exists(key string) bool {
	// does not have any err message to be checked, it return either 1 or 0
	reply, _ := redis.Int(r.Do("EXISTS", r.addPrefix(key)))

	if reply == 1 {
		return true
	}

	return false // means reply is 0, key does not exist
}

// Ping pings the redis server to check if it is alive or not
// If the server is not alive will return a proper error
func (r *RedisSession) Ping() error {
	reply, err := redis.String(r.Do("PING"))
	if err != nil {
		return err
	}

	if reply != "PONG" {
		return fmt.Errorf("reply string is wrong!: %s", reply)
	}

	return nil
}

// Scard gets the member count of a Set with given key
func (r *RedisSession) Scard(key string) (int, error) {
	reply, err := redis.Int(r.Do("SCARD", key))
	if err != nil {
		return 0, err
	}

	return reply, nil
}
