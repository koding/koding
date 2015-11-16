package awspurge

import (
	"fmt"
	"sync"

	"github.com/aws/aws-sdk-go/service/ec2"
	"github.com/hashicorp/go-multierror"
)

// resourceLimit defines the number of resources that can be terminated at once
// for a given resource
const resourceLimit = 100

func (p *Purge) terminateResources(fn func(*ec2.EC2) error) error {
	var (
		wg sync.WaitGroup
		mu sync.Mutex

		multiErrors error
	)

	for r, s := range p.services.ec2 {
		wg.Add(1)

		go func(region string, svc *ec2.EC2) {
			err := fn(svc)
			if err != nil {
				mu.Lock()
				multiErrors = multierror.Append(multiErrors, err)
				mu.Unlock()
			}
			wg.Done()
		}(r, s)
	}

	wg.Wait()
	return multiErrors
}

// DeleteInstances terminates all instances on all regions
func (p *Purge) DeleteInstances() error {
	fn := func(svc *ec2.EC2) error {
		region := *svc.Config.Region

		resources, ok := p.resources[region]
		if !ok {
			return fmt.Errorf("Couldn't find resources for region %s", region)
		}

		if resources.instances == nil {
			return fmt.Errorf("Instances are not fetched for region %s", region)
		}

		instanceIds := make([]*string, len(resources.instances))
		for i, instance := range resources.instances {
			instanceIds[i] = instance.InstanceId
		}

		if len(instanceIds) > resourceLimit {
			return fmt.Errorf("Too many instances(%d) found for region '%s'. Aborting", len(instanceIds), region)
		}

		input := &ec2.TerminateInstancesInput{
			InstanceIds: instanceIds,
		}

		_, err := svc.TerminateInstances(input)
		return err
	}

	return p.terminateResources(fn)
}

// DeleteVolumes terminates all volumes on all regions
func (p *Purge) DeleteVolumes() error {
	fn := func(svc *ec2.EC2) error {
		region := *svc.Config.Region

		resources, ok := p.resources[region]
		if !ok {
			return fmt.Errorf("Couldn't find resources for region %s", region)
		}

		if resources.volumes == nil {
			return fmt.Errorf("volumes are not fetched for region %s", region)
		}

		volumes := make([]*string, len(resources.volumes))
		for i, volume := range resources.volumes {
			volumes[i] = volume.VolumeId
		}

		if len(volumes) > resourceLimit {
			return fmt.Errorf("Too many volumes(%d) found for region '%s'. Aborting",
				len(volumes), region)
		}

		var multiErrors error

		for _, volumeId := range volumes {
			input := &ec2.DeleteVolumeInput{
				VolumeId: volumeId,
			}
			_, err := svc.DeleteVolume(input)
			if err != nil {
				multiErrors = multierror.Append(multiErrors, err)
			}
		}
		return multiErrors
	}

	return p.terminateResources(fn)
}

// DeleteKeyPairs delete all key pairs on all regions
func (p *Purge) DeleteKeyPairs() error {
	fn := func(svc *ec2.EC2) error {
		region := *svc.Config.Region

		resources, ok := p.resources[region]
		if !ok {
			return fmt.Errorf("Couldn't find resources for region %s", region)
		}

		if resources.keyPairs == nil {
			return fmt.Errorf("keyPairs are not fetched for region %s", region)
		}

		keyPairs := make([]*string, len(resources.keyPairs))
		for i, keyPair := range resources.keyPairs {
			keyPairs[i] = keyPair.KeyName
		}

		if len(keyPairs) > resourceLimit {
			return fmt.Errorf("Too many keyPairs(%d) found for region '%s'. Aborting",
				len(keyPairs), region)
		}

		var multiErrors error

		for _, name := range keyPairs {
			input := &ec2.DeleteKeyPairInput{
				KeyName: name,
			}
			_, err := svc.DeleteKeyPair(input)
			if err != nil {
				multiErrors = multierror.Append(multiErrors, err)
			}
		}
		return multiErrors
	}

	return p.terminateResources(fn)
}

// DeletePlacementGroups delete all placementGroups on all regions
func (p *Purge) DeletePlacementGroups() error {
	fn := func(svc *ec2.EC2) error {
		region := *svc.Config.Region

		resources, ok := p.resources[region]
		if !ok {
			return fmt.Errorf("Couldn't find resources for region %s", region)
		}

		if resources.placementGroups == nil {
			return fmt.Errorf("placementGroups are not fetched for region %s", region)
		}

		placementGroups := make([]*string, len(resources.placementGroups))
		for i, group := range resources.placementGroups {
			placementGroups[i] = group.GroupName
		}

		if len(placementGroups) > resourceLimit {
			return fmt.Errorf("Too many placementGroups(%d) found for region '%s'. Aborting",
				len(placementGroups), region)
		}

		var multiErrors error

		for _, name := range placementGroups {
			input := &ec2.DeletePlacementGroupInput{
				GroupName: name,
			}
			_, err := svc.DeletePlacementGroup(input)
			if err != nil {
				multiErrors = multierror.Append(multiErrors, err)
			}
		}
		return multiErrors
	}

	return p.terminateResources(fn)
}

// DeleteAddresses delete all addresses on all regions
func (p *Purge) DeleteAddresses() error {
	fn := func(svc *ec2.EC2) error {
		region := *svc.Config.Region

		resources, ok := p.resources[region]
		if !ok {
			return fmt.Errorf("Couldn't find resources for region %s", region)
		}

		if resources.addresses == nil {
			return fmt.Errorf("addresses are not fetched for region %s", region)
		}

		addresses := make([]*string, len(resources.addresses))
		for i, addr := range resources.addresses {
			addresses[i] = addr.AssociationId
		}

		if len(addresses) > resourceLimit {
			return fmt.Errorf("Too many addresses(%d) found for region '%s'. Aborting",
				len(addresses), region)
		}

		var multiErrors error

		for _, id := range addresses {
			input := &ec2.DisassociateAddressInput{
				AssociationId: id,
			}
			_, err := svc.DisassociateAddress(input)
			if err != nil {
				multiErrors = multierror.Append(multiErrors, err)
			}
		}
		return multiErrors
	}

	return p.terminateResources(fn)
}
