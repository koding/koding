package services

import "errors"

const (
	ITERABLE = "iterable"
	GITHUB   = "github"
)

var (
	ErrServiceNotFound = errors.New("service is not found")
	ErrMethodNotFound  = errors.New("method is not found")
	ErrInvalidRequest  = errors.New("invalid request")
)

type ServiceFactory struct {
	services map[string]Service
}

func NewServiceFactory() *ServiceFactory {
	return &ServiceFactory{
		services: make(map[string]Service),
	}
}

// Create method lazily loads the given services.
func (sf *ServiceFactory) Create(serviceName string, conf *ServiceConfig) (Service, error) {
	service, ok := sf.services[serviceName]
	if ok {
		return service, nil
	}

	var err error
	switch serviceName {
	case ITERABLE:
		service, err = NewIterable()
	case GITHUB:
		conf.Github.PublicUrl = conf.PublicUrl
		conf.Github.IntegrationUrl = conf.IntegrationAddr
		conf.Github.Log = conf.Log
		service, err = NewGithub(conf.Github)
	default:
		return nil, ErrServiceNotFound
	}

	if err != nil {
		return nil, err
	}

	sf.services[serviceName] = service

	return service, nil
}
