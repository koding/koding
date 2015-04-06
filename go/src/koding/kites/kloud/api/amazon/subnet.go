package amazon

import (
	"errors"
	"fmt"
	"sort"

	"github.com/mitchellh/goamz/ec2"
)

type Subnets []ec2.Subnet

func (s Subnets) Len() int      { return len(s) }
func (s Subnets) Swap(i, j int) { s[i], s[j] = s[j], s[i] }
func (s Subnets) Less(i, j int) bool {
	return s[i].AvailableIpAddressCount > s[j].AvailableIpAddressCount
}

// WithMostIps returns the subnet with the most IP's
func (s Subnets) WithMostIps() ec2.Subnet {
	sort.Sort(s)
	return s[0]
}

// AvailabilityZone returns the subnet with the given zone
func (s Subnets) AvailabilityZone(zone string) (ec2.Subnet, error) {
	for _, subnet := range s {
		if subnet.AvailabilityZone == zone {
			return subnet, nil
		}
	}

	return ec2.Subnet{}, errors.New("subnet not found")
}

func (a *Amazon) SubnetsWithTag(tag string) (Subnets, error) {
	filter := ec2.NewFilter()
	filter.Add("tag-value", tag)

	resp, err := a.Client.DescribeSubnets([]string{}, filter)
	if err != nil {
		return nil, err
	}

	return resp.Subnets, nil
}

func (a *Amazon) SecurityGroupFromVPC(vpcId, tag string) (ec2.SecurityGroupInfo, error) {
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
