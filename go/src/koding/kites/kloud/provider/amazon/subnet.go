package amazon

import "errors"

// SubnetId() returns a single subnetId to be used for creating VPC instances
func (a *AmazonClient) SubnetId() (string, error) {
	subs, err := a.ListSubnets()
	if err != nil {
		return "", err
	}

	if len(subs.Subnets) == 0 {
		return "", errors.New("no subnets available")
	}

	return subs.Subnets[0].SubnetId, nil
}
