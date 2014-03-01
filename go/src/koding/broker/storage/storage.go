package storage

import (
	"errors"
	"koding/databases/redis"
	"koding/tools/config"
	"time"
)

var conf *config.Config

type Backend int

const (
	REDIS Backend = iota
	SET
)

type Subscriptionable interface {
	Backend() Backend
	Each(f func(item interface{}) bool) error
	Subscribe(routingKeyPrefix ...string) error
	Unsubscribe(routingKeyPrefix ...string) error
	Has(routingKeyPrefix string) (bool, error)
	Len() (int, error)
	Resubscribe(socketId string) (bool, error)
	ClearWithTimeout(duration time.Duration) error
}

func NewStorage(c *config.Config, cacheType Backend, socketId string) (Subscriptionable, error) {
	if c == nil {
		return nil, errors.New("Config is passed as nil. Aborting.")
	}
	conf = c
	return newSet(socketId)
}

func NewRedisStorage(s *redis.SingletonSession, c *config.Config, socketId string) (Subscriptionable, error) {
	if c == nil {
		return nil, errors.New("Config is passed as nil. Aborting.")
	}
	conf = c
	return newRedis(s, socketId)
}
