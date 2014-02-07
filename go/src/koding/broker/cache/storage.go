package cache

import (
	"errors"
	"koding/tools/config"
)

var conf *config.Config

type Subscriptionable interface {
	Each(f func(item interface{}) bool) error
	Subscribe(routingKeyPrefix string) error
	Unsubscribe(routingKeyPrefix string) error
	Has(routingKeyPrefix string) (bool, error)
	Len() (int, error)
	Resubscribe(socketID string) (bool, error)
	ClearWithTimeout() error
}

type SubscriptionStorage struct {
	storage Subscriptionable
}

func NewStorage(c *config.Config, cacheType, socketID string) (*SubscriptionStorage, error) {
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

	return &SubscriptionStorage{
		storage: s,
	}, nil

}

func (s *SubscriptionStorage) Each(f func(item interface{}) bool) error {
	return s.storage.Each(f)
}

func (s *SubscriptionStorage) Subscribe(routingKeyPrefix string) error {
	return s.storage.Subscribe(routingKeyPrefix)
}
func (s *SubscriptionStorage) Unsubscribe(routingKeyPrefix string) error {
	return s.storage.Unsubscribe(routingKeyPrefix)
}

func (s *SubscriptionStorage) Has(routingKeyPrefix string) (bool, error) {
	return s.storage.Has(routingKeyPrefix)
}

func (s *SubscriptionStorage) Len() (int, error) {
	return s.storage.Len()
}

func (s *SubscriptionStorage) Resubscribe(socketID string) (bool, error) {
	return s.storage.Resubscribe(socketID)
}

func (s *SubscriptionStorage) ClearWithTimeout() error {
	return s.storage.ClearWithTimeout()
}
