package storage

import (
	"errors"
	"koding/tools/config"
	"time"
)

var conf *config.Config

type Subscriptionable interface {
	Each(f func(item interface{}) bool) error
	Subscribe(routingKeyPrefix ...string) error
	Unsubscribe(routingKeyPrefix ...string) error
	Has(routingKeyPrefix string) (bool, error)
	Len() (int, error)
	Resubscribe(socketID string) (bool, error)
	ClearWithTimeout(duration time.Duration) error
}

func NewStorage(c *config.Config, cacheType, socketID string) (Subscriptionable, error) {
	if c == nil {
		return nil, errors.New("Config is passed as nil. Aborting.")
	}
	conf = c

	var err error
	var s Subscriptionable

	switch cacheType {
	case "redis":
		s, err = newRedis(socketID)
	default:
		s, err = newSubscriptionSet(socketID)
	}

	if err != nil {
		return nil, err
	}

	return s, nil
}
