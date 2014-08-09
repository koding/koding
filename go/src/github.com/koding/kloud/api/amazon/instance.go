package amazon

import (
	"errors"
	"fmt"

	"github.com/mitchellh/goamz/ec2"
)

var ErrNoInstances = errors.New("no instances found")

func (a *Amazon) CreateInstance() (*ec2.RunInstancesResp, error) {
	if a.Builder.SourceAmi == "" {
		return nil, errors.New("source ami is empty")
	}

	if a.Builder.InstanceType == "" {
		return nil, errors.New("instance type is empty")
	}

	securityGroups := []ec2.SecurityGroup{{Id: a.Builder.SecurityGroupId}}

	runOpts := &ec2.RunInstances{
		ImageId:                  a.Builder.SourceAmi,
		MinCount:                 1,
		MaxCount:                 1,
		KeyName:                  a.Builder.KeyPair,
		InstanceType:             a.Builder.InstanceType,
		AssociatePublicIpAddress: true,
		SecurityGroups:           securityGroups,
		SubnetId:                 a.Builder.SubnetId,
		UserData:                 a.Builder.UserData,
	}

	return a.Client.RunInstances(runOpts)
}

func (a *Amazon) Instance(id string) (ec2.Instance, error) {
	resp, err := a.Client.Instances([]string{id}, ec2.NewFilter())
	if err != nil {
		return ec2.Instance{}, err
	}

	if len(resp.Reservations) != 1 {
		fmt.Errorf("the instance ID '%s' does not exist", id)
		return ec2.Instance{}, ErrNoInstances
	}

	return resp.Reservations[0].Instances[0], nil
}

func (a *Amazon) InstancesByFilter(filter *ec2.Filter) ([]ec2.Instance, error) {
	if filter == nil {
		filter = ec2.NewFilter()
	}

	resp, err := a.Client.Instances([]string{}, filter)
	if err != nil {
		return nil, err
	}

	if len(resp.Reservations) == 0 {
		return nil, ErrNoInstances
	}

	// we don't care about reservations and every reservation struct returns
	// only on single instance. Just collect them and return a list of
	// instances
	instances := make([]ec2.Instance, len(resp.Reservations))
	for i, r := range resp.Reservations {
		instances[i] = r.Instances[0]
	}

	return instances, nil
}

func (a *Amazon) SecurityGroup(name string) (ec2.SecurityGroup, error) {
	// Somehow only filter works, defining inside SecurityGroup doesn't work
	filter := ec2.NewFilter()
	filter.Add("group-name", name)

	resp, err := a.Client.SecurityGroups([]ec2.SecurityGroup{}, filter)
	if err != nil {
		return ec2.SecurityGroup{}, err
	}

	if len(resp.Groups) != 1 {
		return ec2.SecurityGroup{}, fmt.Errorf("the security group name '%s' does not exist", name)
	}

	return resp.Groups[0].SecurityGroup, nil
}

func (a *Amazon) ListVPCs() (*ec2.VpcsResp, error) {
	return a.Client.DescribeVpcs([]string{}, ec2.NewFilter())
}

func (a *Amazon) ListSubnets() (*ec2.SubnetsResp, error) {
	return a.Client.DescribeSubnets([]string{}, ec2.NewFilter())
}
