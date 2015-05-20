package services

import "errors"

const (
	ITERABLE = "iterable"
)

var ErrServiceNotFound = errors.New("service is not found")

type ServiceFactory struct{}

func NewServiceFactory() *ServiceFactory {
	return &ServiceFactory{}
}

func (sf *ServiceFactory) Create(serviceName string, input *ServiceInput) (Service, error) {
	switch serviceName {
	case ITERABLE:
		return NewIterable(input)
	}

	return nil, ErrServiceNotFound
}
