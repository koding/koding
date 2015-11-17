package awspurge

import (
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/ec2"
	"github.com/aws/aws-sdk-go/service/elb"
	"github.com/hashicorp/go-multierror"
)

func (p *Purge) describeElbResources(fn func(*elb.ELB) error) {
	for _, s := range p.services.elb {
		p.fetchWg.Add(1)

		go func(svc *elb.ELB) {
			err := fn(svc)
			if err != nil {
				p.fetchMu.Lock()
				p.fetchErrs = multierror.Append(p.fetchErrs, err)
				p.fetchMu.Unlock()
			}

			p.fetchWg.Done()
		}(s)
	}
}

func (p *Purge) describeResources(fn func(*ec2.EC2) error) {
	for _, s := range p.services.ec2 {
		p.fetchWg.Add(1)

		go func(svc *ec2.EC2) {
			err := fn(svc)
			if err != nil {
				p.fetchMu.Lock()
				p.fetchErrs = multierror.Append(p.fetchErrs, err)
				p.fetchMu.Unlock()
			}

			p.fetchWg.Done()
		}(s)
	}
}

func (p *Purge) FetchInstances() {
	describeInstances := func(svc *ec2.EC2) error {
		resp, err := svc.DescribeInstances(nil)
		if err != nil {
			return err
		}

		instances := make([]*ec2.Instance, 0)
		if resp.Reservations != nil {
			for _, reserv := range resp.Reservations {
				if len(reserv.Instances) != 0 {
					instances = append(instances, reserv.Instances...)
				}
			}
		}

		region := *svc.Config.Region

		p.resourceMu.Lock()
		p.resources[region].instances = instances
		p.resourceMu.Unlock()
		return nil
	}

	p.describeResources(describeInstances)
}

func (p *Purge) FetchVolumes() {
	describeVolumes := func(svc *ec2.EC2) error {
		resp, err := svc.DescribeVolumes(nil)
		if err != nil {
			return err
		}

		volumes := resp.Volumes
		region := *svc.Config.Region

		p.resourceMu.Lock()
		p.resources[region].volumes = volumes
		p.resourceMu.Unlock()
		return nil
	}

	p.describeResources(describeVolumes)
}

func (p *Purge) FetchKeyPairs() {
	fn := func(svc *ec2.EC2) error {
		resp, err := svc.DescribeKeyPairs(nil)
		if err != nil {
			return err
		}

		resources := resp.KeyPairs
		region := *svc.Config.Region

		p.resourceMu.Lock()
		p.resources[region].keyPairs = resources
		p.resourceMu.Unlock()
		return nil
	}

	p.describeResources(fn)
}

func (p *Purge) FetchPlacementGroups() {
	fn := func(svc *ec2.EC2) error {
		resp, err := svc.DescribePlacementGroups(nil)
		if err != nil {
			return err
		}

		resources := resp.PlacementGroups
		region := *svc.Config.Region

		p.resourceMu.Lock()
		p.resources[region].placementGroups = resources
		p.resourceMu.Unlock()
		return nil
	}

	p.describeResources(fn)
}

func (p *Purge) FetchAddresses() {
	fn := func(svc *ec2.EC2) error {
		resp, err := svc.DescribeAddresses(nil)
		if err != nil {
			return err
		}

		resources := resp.Addresses
		region := *svc.Config.Region

		p.resourceMu.Lock()
		p.resources[region].addresses = resources
		p.resourceMu.Unlock()
		return nil
	}

	p.describeResources(fn)
}

func (p *Purge) FetchSnapshots() {
	fn := func(svc *ec2.EC2) error {
		input := &ec2.DescribeSnapshotsInput{
			OwnerIds: stringSlice("self"),
		}

		resp, err := svc.DescribeSnapshots(input)
		if err != nil {
			return err
		}

		resources := resp.Snapshots
		region := *svc.Config.Region

		p.resourceMu.Lock()
		p.resources[region].snapshots = resources
		p.resourceMu.Unlock()
		return nil
	}

	p.describeResources(fn)
}

func (p *Purge) FetchSecurityGroups() {
	fn := func(svc *ec2.EC2) error {
		resp, err := svc.DescribeSecurityGroups(nil)
		if err != nil {
			return err
		}

		resources := resp.SecurityGroups
		region := *svc.Config.Region

		p.resourceMu.Lock()
		p.resources[region].securityGroups = resources
		p.resourceMu.Unlock()
		return nil
	}

	p.describeResources(fn)
}

func (p *Purge) FetchLoadBalancers() {
	fn := func(svc *elb.ELB) error {
		resp, err := svc.DescribeLoadBalancers(nil)
		if err != nil {
			return err
		}

		loadBalancers := resp.LoadBalancerDescriptions
		region := *svc.Config.Region

		p.resourceMu.Lock()
		p.resources[region].loadBalancers = loadBalancers
		p.resourceMu.Unlock()
		return nil
	}

	p.describeElbResources(fn)
}

func (p *Purge) FetchVpcs() {
	fn := func(svc *ec2.EC2) error {
		resp, err := svc.DescribeVpcs(nil)
		if err != nil {
			return err
		}

		resources := resp.Vpcs
		region := *svc.Config.Region

		p.resourceMu.Lock()
		p.resources[region].vpcs = resources
		p.resourceMu.Unlock()
		return nil
	}

	p.describeResources(fn)
}

func (p *Purge) FetchSubnets() {
	fn := func(svc *ec2.EC2) error {
		resp, err := svc.DescribeSubnets(nil)
		if err != nil {
			return err
		}

		resources := resp.Subnets
		region := *svc.Config.Region

		p.resourceMu.Lock()
		p.resources[region].subnets = resources
		p.resourceMu.Unlock()
		return nil
	}

	p.describeResources(fn)
}

func (p *Purge) FetchNetworkAcls() {
	fn := func(svc *ec2.EC2) error {
		resp, err := svc.DescribeNetworkAcls(nil)
		if err != nil {
			return err
		}

		resources := resp.NetworkAcls
		region := *svc.Config.Region

		p.resourceMu.Lock()
		p.resources[region].networkAcls = resources
		p.resourceMu.Unlock()
		return nil
	}

	p.describeResources(fn)
}

func (p *Purge) FetchInternetGateways() {
	fn := func(svc *ec2.EC2) error {
		resp, err := svc.DescribeInternetGateways(nil)
		if err != nil {
			return err
		}

		resources := resp.InternetGateways
		region := *svc.Config.Region

		p.resourceMu.Lock()
		p.resources[region].internetGateways = resources
		p.resourceMu.Unlock()
		return nil
	}

	p.describeResources(fn)
}

func (p *Purge) FetchRouteTables() {
	fn := func(svc *ec2.EC2) error {
		resp, err := svc.DescribeRouteTables(nil)
		if err != nil {
			return err
		}

		resources := resp.RouteTables
		region := *svc.Config.Region

		p.resourceMu.Lock()
		p.resources[region].routeTables = resources
		p.resourceMu.Unlock()
		return nil
	}

	p.describeResources(fn)
}

// stringSlice is an helper method to convert a slice of strings into a slice
// of pointer of strings. Needed for various aws/ec2 commands.
func stringSlice(vals ...string) []*string {
	a := make([]*string, len(vals))

	for i, v := range vals {
		a[i] = aws.String(v)
	}

	return a
}
