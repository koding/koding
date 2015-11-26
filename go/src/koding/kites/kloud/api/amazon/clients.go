package amazon

import (
	"fmt"

	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/koding/logging"
)

// ProductionRegions describes EC2 regions used in production.
var ProductionRegions = []string{
	"us-east-1",
	"ap-southeast-1",
	"us-west-2",
	"eu-west-1",
}

// ClientOptions describes configuration for a Client.
type ClientOptions struct {
	// Credentials contains access key, secret and/or token.
	Credentials *credentials.Credentials

	// Regions contains 1 or many region names.
	Regions []string

	// Log, when non-nil, is used for verbose logging by *ec2.EC2 client.
	Log logging.Logger

	// MaxResults sets the limit for Describe* calls.
	MaxResults int64
}

// Clients provides wrappers for a EC2 client per region.
type Clients struct {
	regions map[string]*Client // read-only, written once on New()
}

// NewClientPerRegion is returning a new multi clients for the given
// regions names.
func NewClientPerRegion(opts *ClientOptions) (*Clients, error) {
	// Validate regions - ensure no duplicates or no empty items.
	c := &Clients{
		regions: make(map[string]*Client, len(opts.Regions)),
	}
	for i, region := range opts.Regions {
		if region == "" {
			return nil, fmt.Errorf("empty region at i=%d", i)
		}
		if _, ok := c.regions[region]; ok {
			return nil, fmt.Errorf("duplicated region %q at i=%d", region, i)
		}
		opts := &ClientOptions{
			Credentials: opts.Credentials,
			Regions:     []string{region},
			Log:         opts.Log.New(region),
			MaxResults:  opts.MaxResults,
		}
		client, err := NewClient(opts)
		if err != nil {
			return nil, err
		}
		c.regions[region] = client
	}
	return c, nil
}

// Region gives a client for the given region.
//
// If there's no client instantiated for the given region, the method returns
// *NotFoundError error.
func (c Clients) Region(region string) (*Client, error) {
	client, ok := c.regions[region]
	if !ok {
		return nil, newNotFoundError("Region", fmt.Errorf("no client found for %q region", region))
	}
	return client, nil
}

// Regions returns all instantiated clients per region.
//
// The returned map is meant to be used for a read-only access only,
/// as it's not safe to mutate the map.
func (c Clients) Regions() map[string]*Client {
	return c.regions
}

// Zones gives all availability zones for the given region.
//
// If there's no client instantiated for the given region, thus no availability zones,
// the method returns *NotFoundError error.
func (c Clients) Zones(region string) ([]string, error) {
	client, ok := c.regions[region]
	if !ok {
		return nil, newNotFoundError("Region", fmt.Errorf("no zones found for %q region", region))
	}
	return client.Zones, nil
}
