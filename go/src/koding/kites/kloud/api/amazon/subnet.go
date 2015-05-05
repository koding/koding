package amazon

import (
	"errors"
	"fmt"
	"sort"
	"time"

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
	if tag != "" {
		filter.Add("tag-key", tag)
	}

	resp, err := a.Client.SecurityGroups([]ec2.SecurityGroup{}, filter)
	if err != nil {
		return ec2.SecurityGroupInfo{}, err
	}

	if len(resp.Groups) != 1 {
		return ec2.SecurityGroupInfo{}, fmt.Errorf("no security groups for VPC id %s available", vpcId)
	}

	return resp.Groups[0], nil
}

func (a *Amazon) CreateOrGetSecurityGroup(groupName, vpcId string) (ec2.SecurityGroup, error) {
	group, err := a.SecurityGroup(groupName)
	if err == nil && group.VpcId == vpcId {
		return group, nil
	}

	// we couldn't find the security group name via the given groupname(either
	// it doesn't exists or it doesn't matc the given vpcID). Go and try to
	// fetch it via the given vpcId.
	g, err := a.SecurityGroupFromVPC(vpcId, "")
	if err == nil {
		return g.SecurityGroup, nil
	}

	opts := ec2.SecurityGroup{
		Name:        groupName,
		Description: "Koding VMs group",
		VpcId:       vpcId,
	}

	resp, err := a.Client.CreateSecurityGroup(opts)
	if err != nil {
		return ec2.SecurityGroup{}, err
	}

	// Authorize the SSH and Klient access
	perms := []ec2.IPPerm{
		ec2.IPPerm{
			Protocol:  "tcp",
			FromPort:  0,
			ToPort:    65535,
			SourceIPs: []string{"0.0.0.0/0"},
		},
	}

	// We loop and retry this a few times because sometimes the security
	// group isn't available immediately because AWS resources are eventaully
	// consistent.
	for i := 0; i < 5; i++ {
		_, err = a.Client.AuthorizeSecurityGroup(resp.SecurityGroup, perms)
		if err == nil {
			break
		}

		time.Sleep((time.Duration(i) * time.Second) + 1)
	}
	if err != nil {
		return ec2.SecurityGroup{}, err
	}

	return resp.SecurityGroup, nil
}
