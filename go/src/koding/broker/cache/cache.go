package cache

import "github.com/fatih/set"

type SubscriptionSet struct {
	set      *set.Set
	socketID string
}

func NewSubscriptionSet(socketID string) (*SubscriptionSet, error) {
	s := &SubscriptionSet{
		set:      set.New(),
		socketID: socketID,
	}
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
