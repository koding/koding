package lookup

import (
	"fmt"
	"sync"

	"koding/kites/kloud/api/amazon"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/ec2"
	"github.com/koding/logging"
)

// Addresses describe IP address list per region.
//
// TODO(rjeczalik): rename Addresses -> MultiAddresses
type Addresses struct {
	m map[*amazon.Client][]*ec2.Address // read-only, mutated only by NewAddresses
}

// NewAddresses fetches EC2 IP address list from each region.
//
// If log is nil, defaultLogger is used instead.
func NewAddresses(clients *amazon.Clients, log logging.Logger) *Addresses {
	if log == nil {
		log = defaultLogger
	}
	a := newAddresses()
	var wg sync.WaitGroup
	var mu sync.Mutex // protects a.m
	for region, client := range clients.Regions() {
		wg.Add(1)
		go func(region string, client *amazon.Client) {
			defer wg.Done()
			addresses, err := client.Addresses()
			if err != nil {
				log.Error("[%s] fetching IP addresses error: %s", region, err)
				return
			}
			log.Info("[%s] fetched %d addresses", region, len(addresses))
			var ok bool
			mu.Lock()
			if _, ok = a.m[client]; !ok {
				a.m[client] = addresses
			}
			mu.Unlock()
			if ok {
				panic(fmt.Errorf("[%s] duplicated client=%p: %+v", region, client, addresses))
			}
		}(region, client)
	}
	wg.Wait()
	return a
}

func newAddresses() *Addresses {
	return &Addresses{
		m: make(map[*amazon.Client][]*ec2.Address),
	}
}

func (a *Addresses) Count() int {
	var count int = 0

	for _, addrs := range a.m {
		count += len(addrs)
	}

	return count
}

// NotAssociated returns a list of addresses which are not
// associated
func (a *Addresses) NotAssociated() *Addresses {
	filtered := newAddresses()

	for client, addrs := range a.m {
		nonAssociatedAddressess := make([]*ec2.Address, 0)
		for _, addr := range addrs {
			if aws.StringValue(addr.AssociationId) == "" {
				nonAssociatedAddressess = append(nonAssociatedAddressess, addr)
			}
		}
		filtered.m[client] = nonAssociatedAddressess
	}

	return filtered
}

// Release releases all address for the given region/client
func (a *Addresses) Release(client *amazon.Client) {
	if len(a.m) == 0 {
		return
	}

	addresses := a.m[client]
	fmt.Printf("Releasing %d addresses for region %s\n", len(addresses), client.Region)
	for _, addr := range addresses {
		err := client.ReleaseAddress(aws.StringValue(addr.AllocationId))
		if err != nil {
			fmt.Printf("[%s] release ip address error: %s\n", client.Region, err)
		}
	}

	fmt.Printf("Releasing is done for region %s\n", client.Region)
}

// ReleaseAll releases all the given addresses
func (a *Addresses) ReleaseAll() {
	if len(a.m) == 0 {
		return
	}
	var wg sync.WaitGroup
	for client := range a.m {
		wg.Add(1)
		go func(client *amazon.Client) {
			defer wg.Done()
			a.Release(client)
		}(client)
	}
	wg.Wait()
}
