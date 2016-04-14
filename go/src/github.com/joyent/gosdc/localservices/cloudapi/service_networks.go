package cloudapi

import (
	"fmt"
	"strings"

	"github.com/joyent/gosdc/cloudapi"
)

// Networks API

// ListNetworks returns a list of networks that the double knows about
func (c *CloudAPI) ListNetworks() ([]cloudapi.Network, error) {
	if err := c.ProcessFunctionHook(c); err != nil {
		return nil, err
	}

	return c.networks, nil
}

// GetNetwork gets a network by ID
func (c *CloudAPI) GetNetwork(networkID string) (*cloudapi.Network, error) {
	if err := c.ProcessFunctionHook(c, networkID); err != nil {
		return nil, err
	}

	for _, n := range c.networks {
		if strings.EqualFold(n.Id, networkID) {
			return &n, nil
		}
	}

	return nil, fmt.Errorf("Network %s not found", networkID)
}
