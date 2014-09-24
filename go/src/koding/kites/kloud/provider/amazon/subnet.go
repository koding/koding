package amazon

import (
	"fmt"

	"github.com/mitchellh/goamz/ec2"
)

func (a *AmazonClient) SubnetsWithTag(tag string) ([]ec2.Subnet, error) {
	filter := ec2.NewFilter()
	filter.Add("tag-key", tag)

	resp, err := a.Client.DescribeSubnets([]string{}, filter)
	if err != nil {
		return nil, err
	}

	return resp.Subnets, nil
}

func (a *AmazonClient) SecurityGroupFromVPC(vpcId, tag string) (ec2.SecurityGroupInfo, error) {
	filter := ec2.NewFilter()
	filter.Add("vpc-id", vpcId)
	filter.Add("tag-key", tag)

	resp, err := a.Client.SecurityGroups([]ec2.SecurityGroup{}, filter)
	if err != nil {
		return ec2.SecurityGroupInfo{}, err
	}

	if len(resp.Groups) != 1 {
		return ec2.SecurityGroupInfo{}, fmt.Errorf("no security groups for VPC id %s available", vpcId)
	}

	return resp.Groups[0], nil
}
