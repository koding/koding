package services

import "errors"

var ErrServiceNotFound = errors.New("service is not found")

type ServiceFactory struct {
	services map[string]Service
}

func NewServiceFactory() *ServiceFactory {
	sf := &ServiceFactory{}
	sf.services = getServices()

	return sf
}

func getServices() map[string]Service {
	return map[string]Service{
		"iterable": NewIterable(),
	}
}

func (sf *ServiceFactory) Create(serviceName string) (Service, error) {
	service, ok := sf.services[serviceName]
	if !ok {
		return nil, ErrServiceNotFound
	}

	return service, nil
}
