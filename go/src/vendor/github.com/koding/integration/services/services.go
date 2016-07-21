package services

import "errors"

var (
	ErrServiceNotFound   = errors.New("service is not found")
	ErrServiceRegistered = errors.New("service already registered")
)

type Services map[string]Service

func NewServices() *Services {
	return &Services{}
}

func (sf Services) Register(serviceName string, s Service) error {
	_, ok := sf[serviceName]
	if ok {
		return ErrServiceRegistered
	}

	sf[serviceName] = s

	return nil
}

func (sf Services) Get(serviceName string) (Service, error) {
	service, ok := sf[serviceName]
	if !ok {
		return nil, ErrServiceNotFound
	}

	return service, nil
}
