package amazon

import "github.com/mitchellh/goamz/ec2"

func (a *Amazon) AllocateAddress() (*ec2.AllocateAddressResp, error) {
	return a.Client.AllocateAddress(&ec2.AllocateAddress{Domain: "vpc"})
}

func (a *Amazon) AssociateAddress(instanceId, allocationId string) (*ec2.AssociateAddressResp, error) {
	return a.Client.AssociateAddress(&ec2.AssociateAddress{
		InstanceId:   instanceId,
		AllocationId: allocationId,
	})
}

func (a *Amazon) AllocateAndAssociateIP(instanceId string) (string, error) {
	allocateResp, err := a.Client.AllocateAddress(&ec2.AllocateAddress{Domain: "vpc"})
	if err != nil {
		return "", err
	}

	if _, err := a.Client.AssociateAddress(&ec2.AssociateAddress{
		InstanceId:   instanceId,
		AllocationId: allocateResp.AllocationId,
	}); err != nil {
		return "", err
	}

	return allocateResp.PublicIp, nil
}
