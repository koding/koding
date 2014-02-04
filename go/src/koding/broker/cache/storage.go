package cache

type SubscriptionInterface interface {
	Each(f func(item interface{}) bool) error
	Subscribe(routingKeyPrefix string) error
	Unsubscribe(routingKeyPrefix string) error
	Has(routingKeyPrefix string) (bool, error)
	Len() (int, error)
}

type SubscriptionStorage struct {
	storage SubscriptionInterface
}

func NewStorage(cacheType, socketID string) (*SubscriptionStorage, error) {

	var err error
	var be SubscriptionInterface

	switch cacheType {
	case "redis":
		be, err = NewRedis(socketID)
	default:
		be, err = NewSubscriptionSet(socketID)
	}

	if err != nil {
		return nil, err
	}

	return &SubscriptionStorage{
		storage: be,
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
