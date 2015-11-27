package lookup

import (
	"koding/kites/kloud/api/amazon"

	"github.com/koding/logging"

	oldaws "github.com/mitchellh/goamz/aws"
)

var defaultLogger = logging.NewLogger("lookup")

type Lookup struct {
	// values contains a list of instance tags that are identified as test
	// instances. By default all instances are fetched.
	values  []string
	clients *amazon.Clients
	log     logging.Logger
}

// NewAWS gives new Lookup client.
//
// When log is nil, defaultLogger is used instead.
func NewAWS(auth oldaws.Auth, log logging.Logger) (*Lookup, error) {
	if log == nil {
		log = defaultLogger
	}
	clients, err := amazon.NewClientPerRegion(auth, []string{
		"us-east-1",
		"ap-southeast-1",
		"us-west-2",
		"eu-west-1",
	}, log)
	if err != nil {
		return nil, err
	}
	return &Lookup{
		clients: clients,
		log:     log,
	}, nil
}

// FetchIpAddresses fetches all IpAddresses from all regions
func (l *Lookup) FetchIpAddresses() *Addresses {
	return NewAddresses(l.clients, l.log)
}

// FetchInstances fetches all instances from all regions
func (l *Lookup) FetchInstances() *MultiInstances {
	return NewMultiInstances(l.clients, l.log)
}

// FetchVolumes fetches all instances from all regions
func (l *Lookup) FetchVolumes() *MultiVolumes {
	return NewMultiVolumes(l.clients, l.log)
}
