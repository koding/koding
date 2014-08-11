package amazon

import "github.com/mitchellh/goamz/ec2"

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
