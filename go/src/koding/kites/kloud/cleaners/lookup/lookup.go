package lookup

import (
	"koding/kites/kloud/api/amazon"

	"github.com/koding/logging"
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
// When opts.Log is nil, defaultLogger is used instead.
func NewAWS(opts *amazon.ClientOptions) (*Lookup, error) {
	optsCopy := *opts
	if optsCopy.Log == nil {
		optsCopy.Log = defaultLogger
	}
	clients, err := amazon.NewClientPerRegion(&optsCopy)
	if err != nil {
		return nil, err
	}
	return &Lookup{
		clients: clients,
		log:     optsCopy.Log,
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
