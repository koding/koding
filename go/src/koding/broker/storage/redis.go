package storage

import (
	"errors"
	"fmt"
	"koding/databases/redis"
	"time"

	redigo "github.com/garyburd/redigo/redis"
)

var redisSession *redis.RedisSession

type cache struct {
	socketId string
	key      string
}

func createNewSession() (*redis.RedisSession, error) {
	return redis.NewRedisSession(conf.Redis)
}

func generateKey(SocketId string) string {
	return fmt.Sprintf(
		"%s-broker-client-%s",
		conf.Environment,
		SocketId,
	)
}

// convertData changes slice of string to slice of interface
func convertData(commandName string, data ...string) []interface{} {
	newData := make([]interface{}, len(data)+1)
	newData[0] = interface{}(commandName)
	for i, v := range data {
		newData[i+1] = interface{}(v)
	}
	return newData
}

// NewRedis creates a redis backend for storing
// client subscriptions
func newRedis(socketId string) (*cache, error) {
	var err error
	if redisSession == nil {
		redisSession, err = createNewSession()
		if err != nil {
			return nil, err
		}
	}

	if err := redisSession.Ping(); err != nil {
		return nil, err
	}

	cache := &cache{
		socketId: socketId,
		key:      generateKey(socketId),
	}

	return cache, nil
}

// Each traverses on all subscribed items
// if given function returns false, breaks from the iteration
func (c *cache) Each(f func(item interface{}) bool) error {
	members, err := redigo.Strings(redisSession.Do("SMEMBERS", c.key))
	if err != nil {
		return err
	}

	for _, val := range members {
		if !f(val) {
			return nil
		}
	}

	return nil
}

// Subscribe adds one item to the subscription set
// todo - do a performace test for subscribing 2K items at once
func (c *cache) Subscribe(routingKeyPrefixes ...string) error {
	command := convertData(c.key, routingKeyPrefixes...)
	_, err := redigo.Int(redisSession.Do("SADD", command...))
	if err != nil {
		return err
	}
	// discard 0 reply
	// becase, we dont care if it has been added before or not
	return nil

}

// Unsubscribe removes one item from the subscription set
func (c *cache) Unsubscribe(routingKeyPrefixes ...string) error {
	command := convertData(c.key, routingKeyPrefixes...)
	_, err := redigo.Int(redisSession.Do("SREM", command...))
	if err != nil {
		return err
	}
	// discard 0 reply
	// becase, we dont care if it has been removed before or not
	return nil
}

func (c *cache) Resubscribe(clientID string) (bool, error) {
	key := generateKey(clientID)
	reply, err := redigo.Int(redisSession.Do("EXISTS", key))
	if err != nil {
		return false, err
	}

	if reply == 0 {
		return false, nil
	}

	routingKeyPrefixes, err := redigo.Strings(redisSession.Do("SMEMBERS", key))
	if err := c.Subscribe(routingKeyPrefixes...); err != nil {
		return false, err
	}

	return true, nil
}

// Has returns bool result indicating the given routingKeyPrefix is
// subscribed by the client or not
func (c *cache) Has(routingKeyPrefix string) (bool, error) {
	reply, err := redigo.Int(redisSession.Do("SISMEMBER", c.key, routingKeyPrefix))
	if err != nil {
		return false, err
	}

	if reply == 0 {
		return false, nil
	}

	return true, nil
}

// Len returns subscription count for client
func (c *cache) Len() (int, error) {
	reply, err := redigo.Int(redisSession.Do("SCARD", c.key))
	if err != nil {
		return 0, err
	}

	return reply, nil
}

func (c *cache) ClearWithTimeout(duration time.Duration) error {
	reply, err := redigo.Int(redisSession.Do("EXPIRE", c.key, duration.Seconds()))
	if err != nil {
		return err
	}

	if reply == 0 {
		return errors.New("Timeout could not be set")
	}

	return nil

}
