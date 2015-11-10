package amazon

func (a *Amazon) AllocateAndAssociateIP(instanceID string) (string, error) {
	allocID, publicIP, err := a.Client.AllocateAddress("vpc")
	if err != nil {
		return "", err
	}
	if err = a.Client.AssociateAddress(instanceID, allocID); err != nil {
		return "", err
	}
	return publicIP, nil
}
