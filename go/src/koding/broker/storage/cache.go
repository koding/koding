package storage

import (
	"sync"
	"time"

	"github.com/fatih/set"
)

var (
	socketSubscriptionsMap      = make(map[string]*subscriptionSet)
	socketSubscriptionsMapMutex sync.Mutex
)

type subscriptionSet struct {
	set      *set.Set
	socketID string
}

func newSubscriptionSet(socketID string) (*subscriptionSet, error) {
	s := &subscriptionSet{
		set:      set.New(),
		socketID: socketID,
	}
	socketSubscriptionsMapMutex.Lock()
	defer socketSubscriptionsMapMutex.Unlock()

	socketSubscriptionsMap[socketID] = s
	return s, nil
}

func (s *subscriptionSet) Each(f func(item interface{}) bool) error {
	s.set.Each(f)
	// each doesnt return anything
	return nil
}

func (s *subscriptionSet) Subscribe(routingKeyPrefixes ...string) error {
	for _, routingKeyPrefix := range routingKeyPrefixes {
		s.set.Add(routingKeyPrefix)
	}
	// add doesnt return any error
	return nil
}

func (s *subscriptionSet) Unsubscribe(routingKeyPrefixes ...string) error {
	for _, routingKeyPrefix := range routingKeyPrefixes {
		s.set.Remove(routingKeyPrefix)
	}
	// remove doesnt return any error
	return nil
}

func (s *subscriptionSet) Resubscribe(socketID string) (bool, error) {
	socketSubscription, ok := socketSubscriptionsMap[socketID]
	if !ok {
		return false, nil
	}

	socketSubscription.Each(func(routingKeyPrefix interface{}) bool {
		if err := s.Subscribe(routingKeyPrefix.(string)); err != nil {
			return false
		}
		return true
	})
	return true, nil
}

func (s *subscriptionSet) Has(routingKeyPrefix string) (bool, error) {
	// has only returns bool
	return s.set.Has(routingKeyPrefix), nil
}

func (s *subscriptionSet) Len() (int, error) {
	// size only returns count
	return s.set.Size(), nil
}

func (s *subscriptionSet) ClearWithTimeout(duration time.Duration) error {
	time.AfterFunc(duration, func() {
		socketSubscriptionsMapMutex.Lock()
		delete(socketSubscriptionsMap, s.socketID)
		socketSubscriptionsMapMutex.Unlock()
	})
	return nil
}
