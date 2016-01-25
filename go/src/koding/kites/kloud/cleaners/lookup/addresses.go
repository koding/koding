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

func (a *Addresses) InstanceIDs() []string {
	var ids []string

	for _, addrs := range a.m {
		for _, addr := range addrs {
			if id := aws.StringValue(addr.InstanceId); id != "" {
				ids = append(ids, id)
			}
		}
	}

	return ids
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

// NotPaidOptions provides configures filtering addresses by non-paying users.
type NotPaidOptions struct {
	BatchLimit int                        // max number of instances to request at once
	IsPaid     func(username string) bool // whether the given username has $$$
	Log        logging.Logger             // logger

	// CleanAll says whether to clean all EIP owned by non-paying users.
	//
	// By default only EIP owned by non-paying users and attached to stopped
	// instances are cleaned
	CleanAll bool
}

// NotPaid returns a list of addresses which belong to non-paying users.
func (a *Addresses) NotPaid(opts *NotPaidOptions) *Addresses {
	filtered := newAddresses()

	total := 0
	nonPaying := 0

	for client, addrs := range a.m {
		log := opts.Log.New(client.Region)

		uniqAddrs := make(map[string]*ec2.Address)
		pos := 0

		for pos < len(addrs) {
			end := min(pos+opts.BatchLimit, len(addrs))
			batch := addrs[pos:end]
			batchNonPaying := 0

			log.Debug("fetching batch (%d): total[%d:%d] (%d)", len(batch), pos, end, len(addrs))

			pos = end
			ids := make([]string, 0, len(batch))
			revids := make(map[string]*ec2.Address, len(batch))

			for _, addr := range batch {
				if id := aws.StringValue(addr.InstanceId); id != "" {
					ids = append(ids, id)
					revids[id] = addr
				}
			}

			log.Debug("fetching instance ids (%d)", len(ids))

			instances, err := client.InstancesByIDs(ids...)
			if err != nil {
				opts.Log.Error("failed to fetch instances: %s", err)
			}

			for _, instance := range instances {
				id := aws.StringValue(instance.InstanceId)

				tags := amazon.FromTags(instance.Tags)
				username, ok := tags["koding-user"]
				if !ok || username == "" {
					log.Warning("[%s] no value for koding-user tag: %+v", id, tags)
					continue
				}

				if !opts.IsPaid(username) {
					addr, ok := revids[id]
					if !ok {
						log.Warning("[%s] address not found (propably a bug)", id)
						continue
					}
					allocID := aws.StringValue(addr.AllocationId)
					if allocID == "" {
						log.Warning("[%s] empty AllocationId for non-paying user %q", id, username)
						continue
					}

					doClean := opts.CleanAll
					if !doClean {
						ok, err := amazon.IsRunning(instance)
						if err != nil {
							log.Warning("[%s] unable to test whether instance is running: %s", id, err)
							continue
						}

						doClean = ok
					}

					if !doClean {
						log.Info("[%s] ignoring cleaning EIP for non-paying user %q as the instance is running", id, username)
						continue
					}

					if _, ok := uniqAddrs[allocID]; !ok {
						uniqAddrs[allocID] = addr
						log.Debug("[%s] EIP used by non-paying %q user found: AllocationID=%s", id, username, allocID)
						batchNonPaying++
					}

				}
			}

			log.Debug("found %d more non-paying users within the batch", batchNonPaying)
		}

		for _, addr := range uniqAddrs {
			filtered.m[client] = append(filtered.m[client], addr)
		}

		total += len(addrs)
		nonPaying += len(filtered.m[client])
	}

	opts.Log.Debug("found total %d non-paying users (out of %d total)", nonPaying, total)

	return filtered
}

// Release releases all address for the given region/client
//
// TODO(rjeczalik): add logger
func (a *Addresses) Release(client *amazon.Client) {
	if len(a.m) == 0 {
		return
	}

	addresses := a.m[client]
	fmt.Printf("Releasing %d addresses for region %s\n", len(addresses), client.Region)
	for _, addr := range addresses {
		ip := aws.StringValue(addr.PublicIp)

		assocID := aws.StringValue(addr.AssociationId)
		if assocID != "" {
			// EIP is in-use, disassociate it first.
			err := client.DisassociateAddress(assocID)
			if err != nil {
				// Even when it fails, will try to release the EIP.
				fmt.Printf("[%s] disassociate %s EIP error: %s\n", client.Region, ip, err)
			}
		}

		allocID := aws.StringValue(addr.AllocationId)
		err := client.ReleaseAddress(allocID)
		if err != nil {
			fmt.Printf("[%s] release %s EIP error: %s\n", client.Region, ip, err)
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

func min(i, j int) int {
	if i < j {
		return i
	}
	return j
}
