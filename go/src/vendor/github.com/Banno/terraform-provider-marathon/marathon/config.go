package marathon

import (
	"github.com/gambol99/go-marathon"
	"time"
)

type config struct {
	config                   marathon.Config
	Client                   marathon.Marathon
	DefaultDeploymentTimeout time.Duration
}

func (c *config) loadAndValidate() error {
	client, err := marathon.NewClient(c.config)
	c.Client = client
	return err
}
