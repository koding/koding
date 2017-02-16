package amazon

import (
	"fmt"
	"net/url"
	"sort"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/ec2"
)

type Subnets []*ec2.Subnet

func (s Subnets) Len() int      { return len(s) }
func (s Subnets) Swap(i, j int) { s[i], s[j] = s[j], s[i] }
func (s Subnets) Less(i, j int) bool {
	return aws.Int64Value(s[i].AvailableIpAddressCount) > aws.Int64Value(s[j].AvailableIpAddressCount)
}

// WithMostIps returns the subnet with the most IP's
func (s Subnets) WithMostIps() *ec2.Subnet {
	sort.Sort(s)
	return s[0]
}

// AvailabilityZone returns the subnet with the given zone
func (s Subnets) AvailabilityZone(zone string) (*ec2.Subnet, error) {
	for _, subnet := range s {
		if aws.StringValue(subnet.AvailabilityZone) == zone {
			return subnet, nil
		}
	}
	return nil, fmt.Errorf("subnet not found for %q zone", zone)
}

func (a *Amazon) SubnetsWithTag(tag string) (Subnets, error) {
	return a.Client.SubnetsByTag(tag)
}

func (a *Amazon) SecurityGroupFromVPC(vpcId, tag string) (*ec2.SecurityGroup, error) {
	filters := url.Values{
		"vpc-id":  {vpcId},
		"tag-key": {tag},
	}
	return a.Client.SecurityGroupByFilters(filters)
}

func (a *Amazon) CreateOrGetSecurityGroup(groupName, vpcID string) (*ec2.SecurityGroup, error) {
	group, err := a.SecurityGroupByName(groupName)
	if err == nil && aws.StringValue(group.VpcId) == vpcID {
		return group, nil
	}

	// we couldn't find the security group name via the given groupname(either
	// it doesn't exists or it doesn't matc the given vpcID). Go and try to
	// fetch it via the given vpcId.
	group, err = a.SecurityGroupFromVPC(vpcID, "")
	if err == nil {
		return group, nil
	}

	groupID, err := a.Client.CreateSecurityGroup(groupName, vpcID, "Koding VMs group")
	if err != nil {
		return nil, err
	}

	// We loop and retry this a few times because sometimes the security
	// group isn't available immediately because AWS resources are eventually
	// consistent.
	for i := 0; i < 5; i++ {
		err = a.Client.AuthorizeSecurityGroup(groupID, PermAllPorts)
		if err == nil {
			break
		}
		time.Sleep((time.Duration(i) * time.Second) + 1)
	}
	if err != nil {
		return nil, err
	}
	return a.Client.SecurityGroupByID(groupID)
}
