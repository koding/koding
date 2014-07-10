package amazon

func (a *Amazon) CreateKey(name string) (string, error) {
	keyPair, err := a.ec2.CreateKeyPair(name)
	if err != nil {
		return "", err
	}

	return keyPair.KeyMaterial, nil
}

func (a *Amazon) DestroyKey(name string) error {
	_, err := a.ec2.DeleteKeyPair(name)
	return err
}

func (a *Amazon) Showkey(name string) error {
	return nil
}
