package multiec2

import (
	"fmt"
	"log"
	"net"
	"net/http"
	"sync"
	"time"

	"github.com/mitchellh/goamz/aws"
	"github.com/mitchellh/goamz/ec2"
)

type Clients struct {
	// regions is a set of ec2 clients that is bound to a one single region
	regions map[string]*ec2.EC2

	// zones is a list of zones for each given region
	zones map[string][]string

	// protects regions and zones
	sync.Mutex
}

// Clients is returning a new multi clients refernce for the given regions.
func New(auth aws.Auth, regions []string) *Clients {
	// include it here to because the library is not exporting it.
	var retryingTransport = &aws.ResilientTransport{
		Deadline: func() time.Time {
			return time.Now().Add(60 * time.Second)
		},
		DialTimeout: 45 * time.Second, // this is 10 seconds in original
		MaxTries:    3,
		ShouldRetry: awsRetry,
		Wait:        aws.ExpBackoff,
	}

	clients := &Clients{
		regions: make(map[string]*ec2.EC2),
		zones:   make(map[string][]string),
	}

	for _, r := range regions {
		region, ok := aws.Regions[r]
		if !ok {
			log.Printf("multiec2: couldn't find region: '%s'", r)
			continue
		}

		client := ec2.NewWithClient(auth, region, aws.NewClient(retryingTransport))
		clients.regions[region.Name] = client

		resp, err := client.DescribeAvailabilityZones(ec2.NewFilter())
		if err != nil {
			panic(err)
		}

		zones := make([]string, len(resp.Zones))
		for i, zone := range resp.Zones {
			zones[i] = zone.AvailabilityZone.Name
		}

		clients.regions[region.Name] = client
		clients.zones[region.Name] = zones
	}

	return clients
}

// Regions returns a list of Regions with their names and coressponding clients
func (c *Clients) Regions() map[string]*ec2.EC2 {
	return c.regions
}

// Region returns an *ec2.EC2 reference that is used to make API calls to this
// particular region.
func (c *Clients) Region(region string) (*ec2.EC2, error) {
	c.Lock()
	client, ok := c.regions[region]
	if !ok {
		return nil, fmt.Errorf("no client availabile for the given region '%s'", region)
	}
	c.Unlock()
	return client, nil
}

// Zones returns a list of available zones for the given region
func (c *Clients) Zones(region string) ([]string, error) {
	c.Lock()
	zones, ok := c.zones[region]
	if !ok {
		return nil, fmt.Errorf("no zone availabile for the given region '%s'", region)
	}
	c.Unlock()
	return zones, nil
}

// Decide if we should retry a request.  In general, the criteria for retrying
// a request is described here
// http://docs.aws.amazon.com/general/latest/gr/api-retries.html
//
// arslan: this is a slightly modified version that also includes timeouts,
// original file: https://github.com/mitchellh/goamz/blob/master/aws/client.go
func awsRetry(req *http.Request, res *http.Response, err error) bool {
	retry := false

	// Retry if there's a temporary network error or a timeout.
	if neterr, ok := err.(net.Error); ok {
		if neterr.Temporary() {
			retry = true
		}

		if neterr.Timeout() {
			retry = true
		}
	}

	return retry
}
