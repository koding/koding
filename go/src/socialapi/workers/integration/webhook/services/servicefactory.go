package services

import "errors"

var ErrServiceNotFound = errors.New("service is not found")

type ServiceFactory struct{}

func NewServiceFactory() *ServiceFactory {
	sf := &ServiceFactory{}

	return sf
}

func (sf *ServiceFactory) Create(serviceName string, input *ServiceInput) (Service, error) {
	switch serviceName {
	case "iterable":
		return NewIterable(input)
	}

	return nil, ErrServiceNotFound
}
