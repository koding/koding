package cache

import (
	"sync"
	"time"

	"github.com/fatih/set"
)

var (
	socketSubscriptionsMap      = make(map[string]*SubscriptionSet)
	socketSubscriptionsMapMutex sync.Mutex
)

type SubscriptionSet struct {
	set      *set.Set
	socketID string
}

func NewSubscriptionSet(socketID string) (*SubscriptionSet, error) {
	s := &SubscriptionSet{
		set:      set.New(),
		socketID: socketID,
	}
	socketSubscriptionsMapMutex.Lock()
	defer socketSubscriptionsMapMutex.Unlock()

	socketSubscriptionsMap[socketID] = s
	return s, nil
}

func (s *SubscriptionSet) Each(f func(item interface{}) bool) error {
	s.set.Each(f)
	// each doesnt return anything
	return nil
}

func (s *SubscriptionSet) Subscribe(routingKeyPrefix string) error {
	s.set.Add(routingKeyPrefix)
	// add doesnt return any error
	return nil
}

func (s *SubscriptionSet) Resubscribe(socketID string) (bool, error) {
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

func (s *SubscriptionSet) Unsubscribe(routingKeyPrefix string) error {
	s.set.Remove(routingKeyPrefix)
	// remove doesnt return any error
	return nil
}

func (s *SubscriptionSet) Has(routingKeyPrefix string) (bool, error) {
	// has only returns bool
	return s.set.Has(routingKeyPrefix), nil
}

func (s *SubscriptionSet) Len() (int, error) {
	// size only returns count
	return s.set.Size(), nil
}

func (s *SubscriptionSet) ClearWithTimeout() error {
	time.AfterFunc(5*time.Minute, func() {
		socketSubscriptionsMapMutex.Lock()
		delete(socketSubscriptionsMap, s.socketID)
		socketSubscriptionsMapMutex.Unlock()
	})
	return nil
}
