package lookup

import (
	"fmt"
	"sync"

	"github.com/mitchellh/goamz/ec2"
)

// Instances represents a list of ec2.Instances
type Addresses map[string][]ec2.Address

func (a Addresses) Count() int {
	var count int = 0

	for _, addrs := range a {
		count += len(addrs)
	}

	return count
}

// NotAssociated returns a list of addresses which are not
// associated
func (a Addresses) NotAssociated() Addresses {
	filtered := make(Addresses, 0)

	for region, addrs := range a {
		nonAssociatedAddressess := make([]ec2.Address, 0)
		for _, addr := range addrs {
			if addr.AssociationId == "" {
				nonAssociatedAddressess = append(nonAssociatedAddressess, addr)
			}
		}

		filtered[region] = nonAssociatedAddressess
	}

	return filtered
}

// Release releases all address for the given region/client
func (a Addresses) Release(client *ec2.EC2) {
	if len(a) == 0 {
		return
	}

	addresses := a[client.Region.Name]
	fmt.Printf("Releasing %d addresses for region %s\n", len(addresses), client.Region.Name)
	for _, addr := range addresses {
		_, err := client.ReleaseAddress(addr.AllocationId)
		if err != nil {
			fmt.Printf("[%s] release ip address error: %s\n", client.Region.Name, err)
		}
	}
}

// ReleaseAll releases all the given addresses
func (l *Lookup) ReleaseAll(addressess Addresses) {
	if len(addressess) == 0 {
		return
	}

	var wg sync.WaitGroup

	for _, client := range l.clients.Regions() {
		wg.Add(1)

		go func(client *ec2.EC2, a Addresses) {
			a.Release(client)
			wg.Done()
		}(client, addressess)
	}

	wg.Wait()
}
