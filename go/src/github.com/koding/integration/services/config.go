package services

import "github.com/koding/logging"

// ServiceConfig includes all configurations
// of the given services
type ServiceConfig struct {
	PublicUrl       string `env:"key=WEBHOOK_MIDDLEWARE_PUBLICURL        default=https://koding.com"`
	IntegrationAddr string `env:"key=WEBHOOK_MIDDLEWARE_INTEGRATIONADDR  default=http://localhost:7300"`
	Github          GithubConfig
	Log             logging.Logger
}
