package amazon

import (
	"fmt"

	"koding/kites/kloud/awscompat"

	"github.com/koding/logging"
	oldaws "github.com/mitchellh/goamz/aws"
)

// Clients provides wrappers for a EC2 client per region.
type Clients struct {
	regions map[string]*Client // read-only, written once on New()
}

// NewClientPerRegion is returning a new multi clients refernce for the given
// regions names.
func NewClientPerRegion(auth oldaws.Auth, regions []string, log logging.Logger) (*Clients, error) {
	// Validate regions - ensure no duplicates or no empty items.
	uniq := make(map[string]struct{})
	for i, region := range regions {
		if region == "" {
			return nil, fmt.Errorf("empty region at i=%d", i)
		}
		if _, ok := uniq[region]; ok {
			return nil, fmt.Errorf("duplicated region %q", region)
		}
		uniq[region] = struct{}{}
	}
	c := &Clients{
		regions: make(map[string]*Client, len(regions)),
	}
	session := awscompat.NewSession(auth)
	for _, region := range regions {
		client, err := NewClient(session, region, log)
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
