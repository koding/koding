package awspurge

import (
	"fmt"
	"sync"

	"github.com/aws/aws-sdk-go/service/ec2"
	"github.com/aws/aws-sdk-go/service/elb"
	"github.com/hashicorp/go-multierror"
)

// resourceLimit defines the number of resources that can be terminated at once
// for a given resource
const resourceLimit = 100

func (p *Purge) terminateEC2Resources(fn func(*ec2.EC2) error) {
	// we don't need to wait for each region independently
	var wg sync.WaitGroup

	for _, s := range p.services.ec2 {
		wg.Add(1)

		go func(svc *ec2.EC2) {
			err := fn(svc)
			if err != nil {
				p.deleteMu.Lock()
				p.deleteErrs = multierror.Append(p.deleteErrs, err)
				p.deleteMu.Unlock()
			}
			wg.Done()
		}(s)
	}

	wg.Wait()
}

func (p *Purge) terminateELBResources(fn func(*elb.ELB) error) {
	// we don't need to wait for each region independently
	var wg sync.WaitGroup

	for _, s := range p.services.elb {
		wg.Add(1)

		go func(svc *elb.ELB) {
			err := fn(svc)
			if err != nil {
				p.deleteMu.Lock()
				p.deleteErrs = multierror.Append(p.deleteErrs, err)
				p.deleteMu.Unlock()
			}
			wg.Done()
		}(s)
	}

	wg.Wait()
}

// DeleteInstances terminates all instances on all regions
func (p *Purge) DeleteInstances() {
	fn := func(svc *ec2.EC2) error {
		region := *svc.Config.Region

		resources, ok := p.resources[region]
		if !ok {
			return fmt.Errorf("Couldn't find resources for region %s", region)
		}

		if resources.instances == nil || len(resources.instances) == 0 {
			return fmt.Errorf("instances are not fetched for region %s", region)
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

	p.terminateEC2Resources(fn)
}

// DeleteVolumes terminates all volumes on all regions
func (p *Purge) DeleteVolumes() {
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

	p.terminateEC2Resources(fn)
}

// DeleteKeyPairs delete all key pairs on all regions
func (p *Purge) DeleteKeyPairs() {
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

	p.terminateEC2Resources(fn)
}

// DeletePlacementGroups delete all placementGroups on all regions
func (p *Purge) DeletePlacementGroups() {
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

	p.terminateEC2Resources(fn)
}

// DeleteAddresses delete all addresses on all regions
func (p *Purge) DeleteAddresses() {
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

	p.terminateEC2Resources(fn)
}

// DeleteSnapshots delete all snapshots on all regions
func (p *Purge) DeleteSnapshots() {
	fn := func(svc *ec2.EC2) error {
		region := *svc.Config.Region

		resources, ok := p.resources[region]
		if !ok {
			return fmt.Errorf("Couldn't find resources for region %s", region)
		}

		if resources.snapshots == nil {
			return fmt.Errorf("snapshots are not fetched for region %s", region)
		}

		snapshots := make([]*string, len(resources.snapshots))
		for i, sn := range resources.snapshots {
			snapshots[i] = sn.SnapshotId
		}

		if len(snapshots) > resourceLimit {
			return fmt.Errorf("Too many snapshots(%d) found for region '%s'. Aborting",
				len(snapshots), region)
		}

		var multiErrors error

		for _, id := range snapshots {
			input := &ec2.DeleteSnapshotInput{
				SnapshotId: id,
			}
			_, err := svc.DeleteSnapshot(input)
			if err != nil {
				multiErrors = multierror.Append(multiErrors, err)
			}
		}
		return multiErrors
	}

	p.terminateEC2Resources(fn)
}

// DeleteLoadBalancers delete all loadbalancers on all regions
func (p *Purge) DeleteLoadBalancers() {
	fn := func(svc *elb.ELB) error {
		region := *svc.Config.Region

		resources, ok := p.resources[region]
		if !ok {
			return fmt.Errorf("Couldn't find resources for region %s", region)
		}

		if resources.loadBalancers == nil {
			return fmt.Errorf("loadBalancers are not fetched for region %s", region)
		}

		loadBalancers := make([]*string, len(resources.loadBalancers))
		for i, elb := range resources.loadBalancers {
			loadBalancers[i] = elb.LoadBalancerName
		}

		if len(loadBalancers) > resourceLimit {
			return fmt.Errorf("Too many loadBalancers(%d) found for region '%s'. Aborting",
				len(loadBalancers), region)
		}

		var multiErrors error

		for _, name := range loadBalancers {
			input := &elb.DeleteLoadBalancerInput{
				LoadBalancerName: name,
			}

			_, err := svc.DeleteLoadBalancer(input)
			if err != nil {
				multiErrors = multierror.Append(multiErrors, err)
			}
		}
		return multiErrors
	}

	p.terminateELBResources(fn)
}

// DeleteVPCs delete all vpcs on all regions
func (p *Purge) DeleteVPCs() {
	fn := func(svc *ec2.EC2) error {
		region := *svc.Config.Region

		resources, ok := p.resources[region]
		if !ok {
			return fmt.Errorf("Couldn't find resources for region %s", region)
		}

		if resources.vpcs == nil {
			return fmt.Errorf("vpcs are not fetched for region %s", region)
		}

		var multiErrors error

		for _, vpc := range resources.vpcs {
			_, err := svc.DeleteVpc(&ec2.DeleteVpcInput{
				VpcId: vpc.VpcId,
			})
			if err != nil {
				multiErrors = multierror.Append(multiErrors, err)
			}
		}
		return multiErrors
	}

	p.terminateEC2Resources(fn)
}

// DeleteSubnets delete all subnets on all regions
func (p *Purge) DeleteSubnets() {
	fn := func(svc *ec2.EC2) error {
		region := *svc.Config.Region

		resources, ok := p.resources[region]
		if !ok {
			return fmt.Errorf("Couldn't find resources for region %s", region)
		}

		if resources.subnets == nil {
			return fmt.Errorf("subnets are not fetched for region %s", region)
		}

		subnets := make([]*string, len(resources.subnets))
		for i, sn := range resources.subnets {
			subnets[i] = sn.SubnetId
		}

		if len(subnets) > resourceLimit {
			return fmt.Errorf("Too many subnets(%d) found for region '%s'. Aborting",
				len(subnets), region)
		}

		var multiErrors error

		for _, id := range subnets {
			input := &ec2.DeleteSubnetInput{
				SubnetId: id,
			}
			_, err := svc.DeleteSubnet(input)
			if err != nil {
				multiErrors = multierror.Append(multiErrors, err)
			}
		}
		return multiErrors
	}

	p.terminateEC2Resources(fn)
}

// DeleteSecurityGroups delete all security groups on all regions
func (p *Purge) DeleteSecurityGroups() {
	fn := func(svc *ec2.EC2) error {
		region := *svc.Config.Region

		resources, ok := p.resources[region]
		if !ok {
			return fmt.Errorf("Couldn't find resources for region %s", region)
		}

		if resources.securityGroups == nil {
			return fmt.Errorf("securityGroups are not fetched for region %s", region)
		}

		securityGroups := make([]*string, len(resources.securityGroups))
		for i, sg := range resources.securityGroups {
			securityGroups[i] = sg.GroupId
		}

		if len(securityGroups) > resourceLimit {
			return fmt.Errorf("Too many securityGroups(%d) found for region '%s'. Aborting",
				len(securityGroups), region)
		}

		var multiErrors error

		for _, id := range securityGroups {
			input := &ec2.DeleteSecurityGroupInput{
				GroupId: id,
			}
			_, err := svc.DeleteSecurityGroup(input)
			if err != nil {
				multiErrors = multierror.Append(multiErrors, err)
			}
		}
		return multiErrors
	}

	p.terminateEC2Resources(fn)
}

// DeleteNetworkAcls delete all network acls on all regions
func (p *Purge) DeleteNetworkAcls() {
	fn := func(svc *ec2.EC2) error {
		region := *svc.Config.Region

		resources, ok := p.resources[region]
		if !ok {
			return fmt.Errorf("Couldn't find resources for region %s", region)
		}

		if resources.networkAcls == nil {
			return fmt.Errorf("networkAcls are not fetched for region %s", region)
		}

		networkAcls := make([]*string, len(resources.networkAcls))
		for i, n := range resources.networkAcls {
			networkAcls[i] = n.NetworkAclId
		}

		if len(networkAcls) > resourceLimit {
			return fmt.Errorf("Too many networkAcls(%d) found for region '%s'. Aborting",
				len(networkAcls), region)
		}

		var multiErrors error

		for _, id := range networkAcls {
			input := &ec2.DeleteNetworkAclInput{
				NetworkAclId: id,
			}

			_, err := svc.DeleteNetworkAcl(input)
			if err != nil {
				multiErrors = multierror.Append(multiErrors, err)
			}
		}
		return multiErrors
	}

	p.terminateEC2Resources(fn)
}

// DeleteInternetGateways delete all igs on all regions
func (p *Purge) DeleteInternetGateways() {
	fn := func(svc *ec2.EC2) error {
		region := *svc.Config.Region

		resources, ok := p.resources[region]
		if !ok {
			return fmt.Errorf("Couldn't find resources for region %s", region)
		}

		if resources.internetGateways == nil {
			return fmt.Errorf("internetGateways are not fetched for region %s", region)
		}

		var multiErrors error

		for _, ig := range resources.internetGateways {
			// we need to detach before we can delete it
			_, err := svc.DetachInternetGateway(&ec2.DetachInternetGatewayInput{
				InternetGatewayId: ig.InternetGatewayId,
				VpcId:             ig.Attachments[0].VpcId,
			})
			if err != nil {
				multiErrors = multierror.Append(multiErrors, err)
			}

			_, err = svc.DeleteInternetGateway(&ec2.DeleteInternetGatewayInput{
				InternetGatewayId: ig.InternetGatewayId,
			})
			if err != nil {
				multiErrors = multierror.Append(multiErrors, err)
			}
		}
		return multiErrors
	}

	p.terminateEC2Resources(fn)
}

// DeleteRouteTables delete all igs on all regions
func (p *Purge) DeleteRouteTables() {
	fn := func(svc *ec2.EC2) error {
		region := *svc.Config.Region

		resources, ok := p.resources[region]
		if !ok {
			return fmt.Errorf("Couldn't find resources for region %s", region)
		}

		if resources.routeTables == nil {
			return fmt.Errorf("routeTables are not fetched for region %s", region)
		}

		var multiErrors error

		for _, r := range resources.routeTables {
			_, err := svc.DeleteRouteTable(&ec2.DeleteRouteTableInput{
				RouteTableId: r.RouteTableId,
			})
			if err != nil {
				multiErrors = multierror.Append(multiErrors, err)
			}
		}
		return multiErrors
	}

	p.terminateEC2Resources(fn)
}
