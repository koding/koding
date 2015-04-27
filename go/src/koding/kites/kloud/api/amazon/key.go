package amazon

import (
	"errors"

	"github.com/mitchellh/goamz/ec2"
)

func (a *Amazon) CreateKey(name, publicKey string) (*ec2.ImportKeyPairResponse, error) {
	return a.Client.ImportKeyPair(name, publicKey)
}

func (a *Amazon) DestroyKey(name string) error {
	_, err := a.Client.DeleteKeyPair(name)
	return err
}

func (a *Amazon) Showkey(name string) (*ec2.KeyPairsResp, error) {
	return a.Client.KeyPairs([]string{name}, ec2.NewFilter())
}

func (a *Amazon) DeployKey() (string, error) {
	resp, err := a.Showkey(a.Builder.KeyPair)
	if err == nil {
		// key is found
		return resp.Keys[0].Name, nil
	}

	// not a ec2 error, return it
	ec2Err, ok := err.(*ec2.Error)
	if !ok {
		return "", err
	}

	// the key has another problem
	if ec2Err.Code != "InvalidKeyPair.NotFound" {
		return "", err
	}

	if a.Builder.PublicKey == "" {
		return "", errors.New("PublicKey is not defined. Can't create key")
	}

	key, err := a.CreateKey(a.Builder.KeyPair, a.Builder.PublicKey)
	if err != nil {
		return "", err
	}

	return key.KeyName, nil
}
