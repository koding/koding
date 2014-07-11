package amazon

import (
	"fmt"

	"github.com/mitchellh/goamz/ec2"
)

func (a *Amazon) CreateKey(name string) (string, error) {
	keyPair, err := a.Client.CreateKeyPair(name)
	if err != nil {
		return "", err
	}

	return keyPair.KeyMaterial, nil
}

func (a *Amazon) DestroyKey(name string) error {
	_, err := a.Client.DeleteKeyPair(name)
	return err
}

func (a *Amazon) Showkey(name string) error {
	resp, err := a.Client.KeyPairs([]string{name}, ec2.NewFilter())
	if err != nil {
		return err
	}

	fmt.Printf("resp %+v\n", resp)

	return nil
}
