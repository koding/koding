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
