package cache

import "github.com/fatih/set"

type SubscriptionSet struct {
	set *set.Set
}

func NewSubscriptionSet() *SubscriptionSet {
	s := &SubscriptionSet{
		set: set.New(),
	}
	return s
}

func (s *SubscriptionSet) Each(f func(item interface{}) bool) {
	s.set.Each(f)
}

func (s *SubscriptionSet) Subscribe(routingKeyPrefix string) error {
	s.set.Add(routingKeyPrefix)
	return nil
}
func (s *SubscriptionSet) Unsubscribe(routingKeyPrefix string) error {
	s.set.Remove(routingKeyPrefix)
	return nil
}

func (s *SubscriptionSet) Has(routingKeyPrefix string) bool {
	return s.set.Has(routingKeyPrefix)
}

func (s *SubscriptionSet) Len() int {
	return s.set.Size()
}
