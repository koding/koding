package awspurge

import (
	"sync"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/ec2"
	"github.com/aws/aws-sdk-go/service/elb"
	"github.com/hashicorp/go-multierror"
)

func (p *Purge) describeElbResources(fn func(*elb.ELB) (interface{}, error)) (map[string]interface{}, error) {
	var (
		wg sync.WaitGroup
		mu sync.Mutex

		multiErrors error
	)

	output := make(map[string]interface{})

	for r, s := range p.services.elb {
		wg.Add(1)

		go func(region string, svc *elb.ELB) {
			out, err := fn(svc)
			if err != nil {
				mu.Lock()
				multiErrors = multierror.Append(multiErrors, err)
				mu.Unlock()
				wg.Done()
				return
			}

			mu.Lock()
			output[region] = out
			mu.Unlock()

			wg.Done()
		}(r, s)
	}

	wg.Wait()

	return output, multiErrors
}

func (p *Purge) describeResources(fn func(*ec2.EC2) (interface{}, error)) (map[string]interface{}, error) {
	var (
		wg sync.WaitGroup
		mu sync.Mutex

		multiErrors error
	)

	output := make(map[string]interface{})

	for r, s := range p.services.ec2 {
		wg.Add(1)

		go func(region string, svc *ec2.EC2) {
			out, err := fn(svc)
			if err != nil {
				mu.Lock()
				multiErrors = multierror.Append(multiErrors, err)
				mu.Unlock()
				wg.Done()
				return
			}

			mu.Lock()
			output[region] = out
			mu.Unlock()

			wg.Done()
		}(r, s)
	}

	wg.Wait()

	return output, multiErrors
}

// DescribeVolumes returns all volumes per region.
func (p *Purge) DescribeVolumes() (map[string][]*ec2.Volume, error) {
	describeVolumes := func(svc *ec2.EC2) (interface{}, error) {
		resp, err := svc.DescribeVolumes(nil)
		if err != nil {
			return nil, err
		}

		return resp.Volumes, nil
	}

	out, err := p.describeResources(describeVolumes)
	if err != nil {
		return nil, err
	}

	volumes := make(map[string][]*ec2.Volume)
	for region, v := range out {
		vols, ok := v.([]*ec2.Volume)
		if !ok {
			continue
		}
		volumes[region] = vols
	}

	return volumes, nil
}

// DescribeInstances returns all instances per region.
func (p *Purge) DescribeInstances() (map[string][]*ec2.Instance, error) {
	describeInstances := func(svc *ec2.EC2) (interface{}, error) {
		resp, err := svc.DescribeInstances(nil)
		if err != nil {
			return nil, err
		}

		instances := make([]*ec2.Instance, 0)
		if resp.Reservations != nil {
			for _, reserv := range resp.Reservations {
				if len(reserv.Instances) != 0 {
					instances = append(instances, reserv.Instances...)
				}
			}
		}

		return instances, nil
	}

	out, err := p.describeResources(describeInstances)
	if err != nil {
		return nil, err
	}

	instances := make(map[string][]*ec2.Instance)
	for region, i := range out {
		ins, ok := i.([]*ec2.Instance)
		if !ok {
			continue
		}
		instances[region] = ins
	}

	return instances, nil
}

// DescribePairs returns all key pairs per region
func (p *Purge) DescribeKeyPairs() (map[string][]*ec2.KeyPairInfo, error) {
	fn := func(svc *ec2.EC2) (interface{}, error) {
		resp, err := svc.DescribeKeyPairs(nil)
		if err != nil {
			return nil, err
		}

		return resp.KeyPairs, nil
	}

	out, err := p.describeResources(fn)
	if err != nil {
		return nil, err
	}

	output := make(map[string][]*ec2.KeyPairInfo)
	for region, r := range out {
		resources, ok := r.([]*ec2.KeyPairInfo)
		if !ok {
			continue
		}
		output[region] = resources
	}

	return output, nil
}

// DescribePlacementGroups returns all placementGroups per region
func (p *Purge) DescribePlacementGroups() (map[string][]*ec2.PlacementGroup, error) {
	fn := func(svc *ec2.EC2) (interface{}, error) {
		resp, err := svc.DescribePlacementGroups(nil)
		if err != nil {
			return nil, err
		}

		return resp.PlacementGroups, nil
	}

	out, err := p.describeResources(fn)
	if err != nil {
		return nil, err
	}

	output := make(map[string][]*ec2.PlacementGroup)
	for region, r := range out {
		resources, ok := r.([]*ec2.PlacementGroup)
		if !ok {
			continue
		}
		output[region] = resources
	}

	return output, nil
}

// DescribeAddresses returns all elastic IP's per region
func (p *Purge) DescribeAddresses() (map[string][]*ec2.Address, error) {
	fn := func(svc *ec2.EC2) (interface{}, error) {
		resp, err := svc.DescribeAddresses(nil)
		if err != nil {
			return nil, err
		}

		return resp.Addresses, nil
	}

	out, err := p.describeResources(fn)
	if err != nil {
		return nil, err
	}

	output := make(map[string][]*ec2.Address)
	for region, r := range out {
		resources, ok := r.([]*ec2.Address)
		if !ok {
			continue
		}
		output[region] = resources
	}

	return output, nil
}

// DescribeSnapshots returns all snapshots per region
func (p *Purge) DescribeSnapshots() (map[string][]*ec2.Snapshot, error) {
	fn := func(svc *ec2.EC2) (interface{}, error) {
		input := &ec2.DescribeSnapshotsInput{
			OwnerIds: stringSlice("self"),
		}

		resp, err := svc.DescribeSnapshots(input)
		if err != nil {
			return nil, err
		}

		return resp.Snapshots, nil
	}

	out, err := p.describeResources(fn)
	if err != nil {
		return nil, err
	}

	output := make(map[string][]*ec2.Snapshot)
	for region, r := range out {
		resources, ok := r.([]*ec2.Snapshot)
		if !ok {
			continue
		}
		output[region] = resources
	}

	return output, nil
}

// DescribeSecurityGroups returns all security groups per region
func (p *Purge) DescribeSecurityGroups() (map[string][]*ec2.SecurityGroup, error) {
	fn := func(svc *ec2.EC2) (interface{}, error) {
		resp, err := svc.DescribeSecurityGroups(nil)
		if err != nil {
			return nil, err
		}

		return resp.SecurityGroups, nil
	}

	out, err := p.describeResources(fn)
	if err != nil {
		return nil, err
	}

	output := make(map[string][]*ec2.SecurityGroup)
	for region, r := range out {
		resources, ok := r.([]*ec2.SecurityGroup)
		if !ok {
			continue
		}
		output[region] = resources
	}

	return output, nil
}

// DescribeLoadBalancers returns all load balancers per region
func (p *Purge) DescribeLoadBalancers() (map[string][]*elb.LoadBalancerDescription, error) {
	fn := func(svc *elb.ELB) (interface{}, error) {
		resp, err := svc.DescribeLoadBalancers(nil)
		if err != nil {
			return nil, err
		}

		return resp.LoadBalancerDescriptions, nil
	}

	out, err := p.describeElbResources(fn)
	if err != nil {
		return nil, err
	}

	output := make(map[string][]*elb.LoadBalancerDescription)
	for region, r := range out {
		resources, ok := r.([]*elb.LoadBalancerDescription)
		if !ok {
			continue
		}
		output[region] = resources
	}

	return output, nil
}

// DescribeVpcs all vpcs per region
func (p *Purge) DescribeVpcs() (map[string][]*ec2.Vpc, error) {
	fn := func(svc *ec2.EC2) (interface{}, error) {
		resp, err := svc.DescribeVpcs(nil)
		if err != nil {
			return nil, err
		}

		return resp.Vpcs, nil
	}

	out, err := p.describeResources(fn)
	if err != nil {
		return nil, err
	}

	output := make(map[string][]*ec2.Vpc)
	for region, r := range out {
		resources, ok := r.([]*ec2.Vpc)
		if !ok {
			continue
		}
		output[region] = resources
	}

	return output, nil
}

// DescribeSubnets all subnets per region
func (p *Purge) DescribeSubnets() (map[string][]*ec2.Subnet, error) {
	fn := func(svc *ec2.EC2) (interface{}, error) {
		resp, err := svc.DescribeSubnets(nil)
		if err != nil {
			return nil, err
		}
		return resp.Subnets, nil
	}

	out, err := p.describeResources(fn)
	if err != nil {
		return nil, err
	}

	output := make(map[string][]*ec2.Subnet)
	for region, r := range out {
		resources, ok := r.([]*ec2.Subnet)
		if !ok {
			continue
		}
		output[region] = resources
	}

	return output, nil
}

// DescribeNetworkAcls all network acls per region
func (p *Purge) DescribeNetworkAcls() (map[string][]*ec2.NetworkAcl, error) {
	fn := func(svc *ec2.EC2) (interface{}, error) {
		resp, err := svc.DescribeNetworkAcls(nil)
		if err != nil {
			return nil, err
		}
		return resp.NetworkAcls, nil
	}

	out, err := p.describeResources(fn)
	if err != nil {
		return nil, err
	}

	output := make(map[string][]*ec2.NetworkAcl)
	for region, r := range out {
		resources, ok := r.([]*ec2.NetworkAcl)
		if !ok {
			continue
		}
		output[region] = resources
	}

	return output, nil
}

// DescribeInternetGatewats all internet gateways per region
func (p *Purge) DescribeInternetGateways() (map[string][]*ec2.InternetGateway, error) {
	fn := func(svc *ec2.EC2) (interface{}, error) {
		resp, err := svc.DescribeInternetGateways(nil)
		if err != nil {
			return nil, err
		}
		return resp.InternetGateways, nil
	}

	out, err := p.describeResources(fn)
	if err != nil {
		return nil, err
	}

	output := make(map[string][]*ec2.InternetGateway)
	for region, r := range out {
		resources, ok := r.([]*ec2.InternetGateway)
		if !ok {
			continue
		}
		output[region] = resources
	}

	return output, nil
}

// DescribeRouteTables all internet gateways per region
func (p *Purge) DescribeRouteTables() (map[string][]*ec2.RouteTable, error) {
	fn := func(svc *ec2.EC2) (interface{}, error) {
		resp, err := svc.DescribeRouteTables(nil)
		if err != nil {
			return nil, err
		}
		return resp.RouteTables, nil
	}

	out, err := p.describeResources(fn)
	if err != nil {
		return nil, err
	}

	output := make(map[string][]*ec2.RouteTable)
	for region, r := range out {
		resources, ok := r.([]*ec2.RouteTable)
		if !ok {
			continue
		}
		output[region] = resources
	}

	return output, nil
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
