package openstack

import "github.com/rackspace/gophercloud"

type KeyPairs []gophercloud.KeyPair

// // Get key id of the key that matches the name
func (k KeyPairs) Filter(name string) gophercloud.KeyPair {
	for _, key := range k {
		if key.Name == name {
			return key
		}
	}

	return gophercloud.KeyPair{}
}

// Keys returns all available public SSH Keys
func (o *Openstack) Keys() (KeyPairs, error) {
	return o.Client.ListKeyPairs()
}

// ShowKey shows the key content for the given key id
func (o *Openstack) ShowKey(name string) (gophercloud.KeyPair, error) {
	return o.Client.ShowKeyPair(name)
}

// ShowKey shows the key content for the given key id
func (o *Openstack) CreateKey(name, publicKey string) (gophercloud.KeyPair, error) {
	n := gophercloud.NewKeyPair{
		Name:      name,
		PublicKey: publicKey,
	}

	return o.Client.CreateKeyPair(n)
}

func (o *Openstack) DestroyKey(name string) error {
	return o.Client.DeleteKeyPair(name)
}
