package amazon

import "errors"

func (a *Amazon) DeployKey() (string, error) {
	_, err := a.KeyPairByName(a.Builder.KeyPair)
	if err != nil && !IsNotFound(err) {
		return "", err
	}
	if a.Builder.PublicKey == "" {
		return "", errors.New("PublicKey is not defined. Can't create key")
	}
	_, err = a.ImportKeyPair(a.Builder.KeyPair, []byte(a.Builder.PublicKey))
	if err != nil {
		return "", err
	}
	return a.Builder.KeyPair, nil
}
