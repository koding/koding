package services

import "github.com/koding/logging"

// ServiceConfig includes all configurations of the given services
type ServiceConfig struct {
	PublicURL       string `env:"key=WEBHOOK_MIDDLEWARE_PUBLICURL        default=https://koding.com"`
	IntegrationAddr string `env:"key=WEBHOOK_MIDDLEWARE_INTEGRATIONADDR  default=http://localhost:7300"`
	Log             logging.Logger
}
