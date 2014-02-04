package cache

import (
	"fmt"
	"koding/databases/redis"
	"koding/tools/config"

	redigo "github.com/garyburd/redigo/redis"
)

type Cache struct {
	socketID string
	session  *redis.RedisSession
	key      string
}

// NewRedis creates a redis backend for storing
// client subscriptions
func NewRedis(socketID string) (*Cache, error) {
	session, err := redis.NewRedisSession(config.Current.Redis)
	if err != nil {
		return nil, err
	}

	cache := &Cache{
		socketID: socketID,
		session:  session,
		key: fmt.Sprintf(
			"%s-broker-client-%s",
			config.Current.Environment,
			socketID,
		),
	}

	return cache, nil
}

// Each traverses on all subscribed items
// if given function returns false, breaks from the iteration
func (c *Cache) Each(f func(item interface{}) bool) error {
	members, err := redigo.Strings(c.session.Do("SMEMBERS", c.key))
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
// todo - change this signature to
// func (c *Cache) Subscribe(routingKeyPrefix ...string) error {
func (c *Cache) Subscribe(routingKeyPrefix string) error {
	_, err := redigo.Int(c.session.Do("SADD", c.key, routingKeyPrefix))
	if err != nil {
		return err
	}
	// discard 0 reply
	// becase, we dont care if it has been added before or not
	return nil

}

// Unsubscribe removes one item from the subscription set
// todo - change this signature to
// func (c *Cache) Unsubscribe(routingKeyPrefix ...string) error {
func (c *Cache) Unsubscribe(routingKeyPrefix string) error {
	_, err := redigo.Int(c.session.Do("SREM", c.key, routingKeyPrefix))
	if err != nil {
		return err
	}
	// discard 0 reply
	// becase, we dont care if it has been removed before or not
	return nil
}

// Has returns bool result indicating the given routingKeyPrefix is
// subscribed by the client or not
func (c *Cache) Has(routingKeyPrefix string) (bool, error) {
	reply, err := redigo.Int(c.session.Do("SISMEMBER", c.key, routingKeyPrefix))
	if err != nil {
		return false, err
	}

	if reply == 0 {
		return false, nil
	}

	return true, nil
}

// Len returns subscription count for client
func (c *Cache) Len() (int, error) {
	reply, err := redigo.Int(c.session.Do("SCARD", c.key))
	if err != nil {
		return 0, err
	}

	return reply, nil
}
