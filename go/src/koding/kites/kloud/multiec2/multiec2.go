package multiec2

import (
	"net"
	"net/http"
	"sync"
	"time"

	"github.com/mitchellh/goamz/aws"
	"github.com/mitchellh/goamz/ec2"
)

type Clients struct {
	regions map[string]*ec2.EC2
	sync.Mutex
}

// Clients is returning a new clients reference
func New(auth aws.Auth) *Clients {
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
	}

	for _, region := range aws.Regions {
		clients.regions[region.Name] = ec2.NewWithClient(
			auth, region, aws.NewClient(retryingTransport),
		)
	}

	return clients
}

// HasRegion checks whether the given region exists or not
func (c *Clients) HasRegion(region string) bool {
	c.Lock()
	_, ok := c.regions[region]
	c.Unlock()
	return ok
}

// Region returns an *ec2.EC2 reference that is used to make API calls to this
// particular region.
func (c *Clients) Region(region string) *ec2.EC2 {
	c.Lock()
	client := c.regions[region]
	c.Unlock()
	return client
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
