package amazon

import (
	"errors"

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
	}

	return a.Client.RunInstances(runOpts)
}
