package amazon

import (
	"errors"
	"fmt"

	"github.com/mitchellh/goamz/ec2"
)

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
	}

	return a.Client.RunInstances(runOpts)
}

func (a *Amazon) Instance(id string) (ec2.Instance, error) {
	resp, err := a.Client.Instances([]string{id}, ec2.NewFilter())
	if err != nil {
		return ec2.Instance{}, err
	}

	if len(resp.Reservations) != 1 {
		return ec2.Instance{}, fmt.Errorf("the instance ID '%s' does not exist", id)
	}

	return resp.Reservations[0].Instances[0], nil
}

func (a *Amazon) ListVPCs() (*ec2.VpcsResp, error) {
	return a.Client.DescribeVpcs([]string{}, ec2.NewFilter())
}

func (a *Amazon) ListSubnets() (*ec2.SubnetsResp, error) {
	return a.Client.DescribeSubnets([]string{}, ec2.NewFilter())
}
