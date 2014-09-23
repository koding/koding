package amazon

import "errors"

// SubnetId() returns a single subnetId to be used for creating VPC instances
// for the given VPC Id.
func (a *AmazonClient) SubnetId(vpcId string) (string, error) {
	subs, err := a.ListSubnetsFromVPC(vpcId)
	if err != nil {
		return "", err
	}

	if len(subs.Subnets) == 0 {
		return "", errors.New("no subnets available")
	}

	return subs.Subnets[0].SubnetId, nil
}
