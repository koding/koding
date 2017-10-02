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

type RedisConf struct {
	Server string
	DB     int
}

var (
	ErrNil               = redis.ErrNil
	ErrTTLNotSet         = errors.New("ttl is not set")
	ErrKeyNotExist       = errors.New("key does not exist")
	ErrDestinationNotSet = errors.New("destination is not set")
	ErrKeysNotSet        = errors.New("keys are not set")
)

// NewRedisSession creates a new Redis Pool with optional Redis Dial configurations.
func NewRedisSession(conf *RedisConf, options ...redis.DialOption) (*RedisSession, error) {
	s := &RedisSession{}
	if len(options) == 0 {
		options = []redis.DialOption{
			redis.DialReadTimeout(5 * time.Second),
			redis.DialWriteTimeout(time.Second),
			redis.DialConnectTimeout(time.Second),
		}
	}

	options = append(options, redis.DialDatabase(conf.DB))

	pool := &redis.Pool{
		MaxIdle:     3,
		MaxActive:   1000,
		IdleTimeout: 30 * time.Second,
		Dial: func() (redis.Conn, error) {
			c, err := redis.Dial("tcp", conf.Server, options...)
			if err != nil {
				return nil, err
			}
			return c, err
		},
		TestOnBorrow: func(c redis.Conn, t time.Time) error {
			_, err := c.Do("PING")
			return err
		},
	}
	s.pool = pool
	// when we use connection pooling
	// dialing and returning an error will be
	// with the request
	return s, nil
}

// Pool Returns the connection pool for redis
func (r *RedisSession) Pool() *redis.Pool {
	return r.pool
}

// Close closes the connection pool for redis
func (r *RedisSession) Close() error {
	return r.pool.Close()
}

// SetPrefix is used to add a prefix to all keys to be used. It is useful for
// creating namespaces for each different application
func (r *RedisSession) SetPrefix(name string) {
	r.prefix = name + ":"
}

func (r *RedisSession) AddPrefix(name string) string {
	return r.prefix + name
}

// Do is a wrapper around redigo's redis.Do method that executes any redis
// command. Do does not support prefix support. Example usage: redis.Do("INCR",
// "counter").
func (r *RedisSession) Do(cmd string, args ...interface{}) (interface{}, error) {
	conn := r.pool.Get()
	// conn.Close() returns an error but we are already returning regarding error
	// while returning the Do(..) response
	defer conn.Close()
	return conn.Do(cmd, args...)
}

// Send is a wrapper around redigo's redis.Send method that writes the
// command to the client's output buffer.
func (r *RedisSession) Send(cmd string, args ...interface{}) error {
	conn := r.pool.Get()
	// conn.Close() returns an error but we are already returning regarding error
	// while returning the Do(..) response
	defer conn.Close()
	return conn.Send(cmd, args...)
}

// Set is used to hold the string value. If key already holds a value, it is
// overwritten, regardless of its type. A return of nil means successfull.
// Example usage: redis.Set("arslan:name", "fatih")
func (r *RedisSession) Set(key, value string) error {
	reply, err := r.Do("SET", r.AddPrefix(key), value)
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
	reply, err := redis.String(r.Do("GET", r.AddPrefix(key)))
	if err != nil {
		return "", err
	}
	return reply, nil
}

// GetInt is used the value of key as an integer. If the key does not exist or
// the stored value is a non-integer, zero is returned. Example usage:
// redis.GetInt("counter")
func (r *RedisSession) GetInt(key string) (int, error) {
	return redis.Int(r.Do("GET", r.AddPrefix(key)))
}

// Del is used to remove the specified keys. Key is ignored if it does not
// exist. It returns the number of keys that were removed. Example usage:
// redis.Del("counter", "arslan:name")
func (r *RedisSession) Del(args ...interface{}) (int, error) {
	prefixed := make([]interface{}, 0)
	for _, arg := range args {
		prefixed = append(prefixed, r.AddPrefix(arg.(string)))
	}

	return redis.Int(r.Do("DEL", prefixed...))
}

// Incr increments the number stored at key by one. If the key does not exist,
// it is set to 0 before performing the operation. An error is returned if the
// key contains a value of the wrong type or contains a string that can not be
// represented as integer
func (r *RedisSession) Incr(key string) (int, error) {
	return redis.Int(r.Do("INCR", r.AddPrefix(key)))
}

// Incrby increments the number stored at key by given number. If the key does
// not exist, it is set to 0 before performing the operation. An error is
// returned if the key contains a value of the wrong type or contains a string
// that can not be represented as integer
func (r *RedisSession) IncrBy(key string, by int64) (int64, error) {
	return redis.Int64(r.Do("INCRBY", r.AddPrefix(key), by))
}

// Decr decrements the number stored at key by one. If the key does not exist,
// it is set to 0 before performing the operation. An error is returned if the
// key contains a value of the wrong type or contains a string that can not be
// represented as integer
func (r *RedisSession) Decr(key string) (int, error) {
	return redis.Int(r.Do("DECR", r.AddPrefix(key)))
}

// Expire sets a timeout on a key. After the timeout has expired, the key will
// automatically be deleted. Calling Expire on a key that has already expire
// set will update the expire value.
func (r *RedisSession) Expire(key string, timeout time.Duration) error {
	seconds := strconv.Itoa(int(timeout.Seconds()))
	reply, err := redis.Int(r.Do("EXPIRE", r.AddPrefix(key), seconds))
	if err != nil {
		return err
	}

	if reply != 1 {
		return errors.New("key does not exist or the timeout could not be set")
	}

	return nil
}

// TTL returns remaining TTL value of the given key. An error is returned
// when TTL is not existed or key is not found
func (r *RedisSession) TTL(key string) (time.Duration, error) {
	reply, err := redis.Int(r.Do("TTL", r.AddPrefix(key)))
	if err != nil {
		return 0, err
	}

	if reply == -1 {
		return 0, ErrTTLNotSet
	}

	if reply == -2 {
		return 0, ErrKeyNotExist
	}

	return time.Duration(reply) * time.Second, nil
}

// Set key to hold the string value and set key to timeout after a given
// number of seconds. This command is equivalent to executing the following commands:
// SET mykey value
// EXPIRE mykey seconds
// SETEX is atomic, and can be reproduced by using the previous two
// commands inside an MULTI / EXEC block. It is provided as a faster alternative
// to the given sequence of operations, because this operation is very common
// when Redis is used as a cache.
// An error is returned when seconds is invalid.
func (r *RedisSession) Setex(key string, timeout time.Duration, item interface{}) error {
	reply, err := redis.String(
		r.Do(
			"SETEX",
			r.AddPrefix(key),
			strconv.Itoa(int(timeout.Seconds())),
			item,
		),
	)
	if err != nil {
		return err
	}

	if reply != "OK" {
		return fmt.Errorf("reply string is wrong!: %s", reply)
	}

	return nil
}

// PubSubConn wraps a Conn with convenience methods for subscribers.
func (r *RedisSession) CreatePubSubConn() *redis.PubSubConn {
	return &redis.PubSubConn{Conn: r.pool.Get()}
}

// Exists returns true if key exists or false if not.
func (r *RedisSession) Exists(key string) bool {
	// does not have any err message to be checked, it return either 1 or 0
	reply, _ := redis.Int(r.Do("EXISTS", r.AddPrefix(key)))

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
	return redis.Int(r.Do("SCARD", r.AddPrefix(key)))
}

// SortedSetIncrBy increments the value of a member
// in a sorted set
//
// This function tries to return last floating value of the item,
// if it fails to parse reply to float64, returns parsing error along with
// Reply it self
func (r *RedisSession) SortedSetIncrBy(key string, incrBy, item interface{}) (float64, error) {
	prefixed := make([]interface{}, 0)
	// add key
	prefixed = append(prefixed, r.AddPrefix(key))

	// add incrBy
	prefixed = append(prefixed, incrBy)

	// add item
	prefixed = append(prefixed, item)

	return redis.Float64(r.Do("ZINCRBY", prefixed...))
}

// ZREVRANGE key start stop [WITHSCORES]
// Returns the specified range of elements in the sorted set stored at key.
// The elements are considered to be ordered from the highest
// to the lowest score. Descending lexicographical order is used
// for elements with equal score.
//
// Apart from the reversed ordering, ZREVRANGE is similar to ZRANGE.
func (r *RedisSession) SortedSetReverseRange(key string, rest ...interface{}) ([]interface{}, error) {
	// create a slice with rest length +1
	// because we are gonna prepend key to it
	prefixedReq := make([]interface{}, len(rest)+1)

	// prepend prefixed key
	prefixedReq[0] = r.AddPrefix(key)

	for key, el := range rest {
		prefixedReq[key+1] = el
	}

	return redis.Values(r.Do("ZREVRANGE", prefixedReq...))
}

// HashSet sets a single element at key with given field and value.
// Returns error state of this operation
func (r *RedisSession) HashSet(key, member string, value interface{}) (int, error) {
	return redis.Int(r.Do("HSET", r.AddPrefix(key), member, value))
}

// HashMultipleSet sets multiple hashset elements stored at key with given field values.
// Returns error state of this operation
func (r *RedisSession) HashMultipleSet(key string, item map[string]interface{}) error {
	reply, err := r.Do("HMSET", redis.Args{}.Add(r.AddPrefix(key)).AddFlat(item)...)
	if err != nil {
		return err
	}

	if reply != "OK" {
		return fmt.Errorf("reply string is wrong!: %s", reply)
	}

	return nil
}

// GetHashMultipleSet returns values of the hashset at stored key with
// requested field order
// Usage: GetHashMultipleSet("canthefason", "name", "age", "birthDate")
func (r *RedisSession) GetHashMultipleSet(key string, rest ...interface{}) ([]interface{}, error) {
	prefixedReq := r.prepareArgsWithKey(key, rest...)
	return redis.Values(r.Do("HMGET", prefixedReq...))
}

// GetHashSetField returns value of the given field of the hash set
func (r *RedisSession) GetHashSetField(key string, field string) (string, error) {
	return redis.String(r.Do("HGET", r.AddPrefix(key), field))
}

// HashGetAll returns all of the fields of a hash value
// Usage: HashGetAll(key)
func (r *RedisSession) HashGetAll(key string) ([]interface{}, error) {
	return redis.Values(r.Do("HGETALL", r.AddPrefix(key)))
}

// HashSetIfNotExists adds the item to given field, when the field
// does not exist. Returns the result of set operation
func (r *RedisSession) HashSetIfNotExists(key, field string, item interface{}) (bool, error) {
	reply, err := redis.Int(r.Do("HSETNX", r.AddPrefix(key), field, item))
	if err != nil {
		return false, err
	}

	return reply == 1, nil
}

// GetHashLength returns the item count of a hash set.
func (r *RedisSession) GetHashLength(key string) (int, error) {
	return redis.Int(r.Do("HLEN", r.AddPrefix(key)))
}

// DeleteHashSetField deletes a given field from hash set and returns number
// of deleted fields count
func (r *RedisSession) DeleteHashSetField(key string, rest ...interface{}) (int, error) {
	prefixedReq := r.prepareArgsWithKey(key, rest...)

	return redis.Int(r.Do("HDEL", prefixedReq...))
}

// AddSetMembers adds given elements to the set stored at key. Given elements
// that are already included in set are ignored.
// Returns successfully added key count and error state
func (r *RedisSession) AddSetMembers(key string, rest ...interface{}) (int, error) {
	prefixedReq := r.prepareArgsWithKey(key, rest...)

	return redis.Int(r.Do("SADD", prefixedReq...))
}

// RemoveSetMembers removes given elements from the set stored at key
// Returns successfully removed key count and error state
func (r *RedisSession) RemoveSetMembers(key string, rest ...interface{}) (int, error) {
	prefixedReq := r.prepareArgsWithKey(key, rest...)

	return redis.Int(r.Do("SREM", prefixedReq...))
}

// GetSetMembers returns all members included in the set at key
// Returns members array and error state
func (r *RedisSession) GetSetMembers(key string) ([]interface{}, error) {
	return redis.Values(r.Do("SMEMBERS", r.AddPrefix(key)))
}

// PopSetMember removes and returns a random element from the set stored at key
func (r *RedisSession) PopSetMember(key string) (string, error) {
	return redis.String(r.Do("SPOP", r.AddPrefix(key)))
}

// IsSetMember checks existence of a member set
func (r *RedisSession) IsSetMember(key string, value string) (int, error) {
	prefixedReq := r.prepareArgsWithKey(key, value)

	return redis.Int(r.Do("SISMEMBER", prefixedReq...))
}

// RandomSetMember returns random from set, but not removes unline PopSetMember
func (r *RedisSession) RandomSetMember(key string) (string, error) {
	return redis.String(r.Do("SRANDMEMBER", r.AddPrefix(key)))
}

// SortBy sorts elements stored at key with given weight and order(ASC|DESC)
//
// i.e. Suppose we have elements stored at key as object_1, object_2 and object_3
// and their weight is relatively stored at object_1:weight, object_2:weight, object_3:weight
// When we give sortBy parameter as *:weight, it gets all weight values and sorts the objects
// at given key with specified order.
func (r *RedisSession) SortBy(key, sortBy, order string) ([]interface{}, error) {
	return redis.Values(r.Do("SORT", r.AddPrefix(key), "by", r.AddPrefix(sortBy), order))
}

// Keys returns all keys with given pattern
// WARNING: Redis Doc says: "Don't use KEYS in your regular application code."
func (r *RedisSession) Keys(key string) ([]interface{}, error) {
	return redis.Values(r.Do("KEYS", r.AddPrefix(key)))
}

// Bool converts the given value to boolean
func (r *RedisSession) Bool(reply interface{}) (bool, error) {
	return redis.Bool(reply, nil)
}

// Int converts the given value to integer
func (r *RedisSession) Int(reply interface{}) (int, error) {
	return redis.Int(reply, nil)
}

// String converts the given value to string
func (r *RedisSession) String(reply interface{}) (string, error) {
	return redis.String(reply, nil)
}

// Int64 converts the given value to 64 bit integer
func (r *RedisSession) Int64(reply interface{}) (int64, error) {
	return redis.Int64(reply, nil)
}

// Values is a helper that converts an array command reply to a
// []interface{}. If err is not equal to nil, then Values returns nil, err.
// Otherwise, Values converts the reply as follows:
// Reply type      Result
// array           reply, nil
// nil             nil, ErrNil
// other           nil, error
func (r *RedisSession) Values(reply interface{}) ([]interface{}, error) {
	return redis.Values(reply, nil)
}

// prepareArgsWithKey helper method prepends key to given variadic parameter
func (r *RedisSession) prepareArgsWithKey(key string, rest ...interface{}) []interface{} {
	prefixedReq := make([]interface{}, len(rest)+1)

	// prepend prefixed key
	prefixedReq[0] = r.AddPrefix(key)

	for key, el := range rest {
		prefixedReq[key+1] = el
	}

	return prefixedReq
}

// SortedSetsUnion creates a combined set from given list of sorted set keys.
//
// See: http://redis.io/commands/zunionstore
func (r *RedisSession) SortedSetsUnion(destination string, keys []string, weights []interface{}, aggregate string) (int64, error) {
	if destination == "" {
		return 0, ErrDestinationNotSet
	}

	lengthOfKeys := len(keys)
	if lengthOfKeys == 0 {
		return 0, ErrKeysNotSet
	}

	prefixed := []interface{}{
		r.AddPrefix(destination), lengthOfKeys,
	}

	for _, key := range keys {
		prefixed = append(prefixed, r.AddPrefix(key))
	}

	if len(weights) != 0 {
		prefixed = append(prefixed, "WEIGHTS")
		prefixed = append(prefixed, weights...)
	}

	if aggregate != "" {
		prefixed = append(prefixed, "AGGREGATE", aggregate)
	}

	return redis.Int64(r.Do("ZUNIONSTORE", prefixed...))
}

// SortedSetScore returns score of a member in a sorted set. If no member,
// an error is returned.
//
// See: http://redis.io/commands/zscore
func (r *RedisSession) SortedSetScore(key string, member interface{}) (float64, error) {
	return redis.Float64(r.Do("ZSCORE", r.AddPrefix(key), member))
}

// SortedSetRem removes a member from a sorted set. If no member, an error
// is returned.
//
// See: http://redis.io/commands/zrem
func (r *RedisSession) SortedSetRem(key string, members ...interface{}) (int64, error) {
	prefixed := []interface{}{r.AddPrefix(key)}
	prefixed = append(prefixed, members...)

	return redis.Int64(r.Do("ZREM", prefixed...))
}

// SortedSetAdds adds updates the element score, and as a side effect, its
// position on the sorted set.
//
// See: http://redis.io/commands/zadd
func (r *RedisSession) SortedSetAddSingle(key, member string, score interface{}) error {
	_, err := r.Do("ZADD", r.AddPrefix(key), score, member)
	return err
}

var (
	NegativeInf = "-inf"
	PositiveInf = "+inf"
)

// SortedSetRangebyScore key min max
// returns all the elements in the sorted set at key with a score
// between min and max.
//
// See: http://redis.io/commands/zrangebyscore
func (r *RedisSession) SortedSetRangebyScore(key string, rest ...interface{}) ([]interface{}, error) {
	prefixed := []interface{}{r.AddPrefix(key)}
	prefixed = append(prefixed, rest...)

	return redis.Values(r.Do("ZRANGEBYSCORE", prefixed...))
}
