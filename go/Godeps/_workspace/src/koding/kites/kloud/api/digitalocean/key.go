package api

import (
	"fmt"
	"net/url"

	"github.com/mitchellh/mapstructure"
	"github.com/mitchellh/packer/builder/digitalocean"
)

type SSHKey struct {
	Id        int    `json:"id"`
	Name      string `json:"name"`
	SSHPubKey string `json:"ssh_pub_key"`
}

type SSHKeys []*SSHKey

// Get key id of the key that matches the name
func (s SSHKeys) GetId(name string) uint {
	for _, key := range s {
		if key.Name == name {
			return uint(key.Id)
		}
	}

	return 0
}

// CreateKey creates a new ssh key with the given name and the associated
// public key. It returns a unique id that is associated with the given
// publicKey. This id is used to show, edit or delete the key.
func (d *DigitalOcean) CreateKey(name, publicKey string) (uint, error) {
	return d.Client.CreateKey(name, publicKey)
}

// DestroyKey removes the ssh key that is associated with the given id.
func (d *DigitalOcean) DestroyKey(keyId uint) error {
	return d.Client.DestroyKey(keyId)
}

// ShowKey shows the key content for the given key id
func (d *DigitalOcean) ShowKey(keyId uint) (*SSHKey, error) {
	path := fmt.Sprintf("ssh_keys/%v", keyId)
	resp, err := digitalocean.NewRequest(*d.Client, path, url.Values{})
	if err != nil {
		return nil, err
	}

	ssh_key, ok := resp["ssh_key"].(map[string]interface{})
	if !ok {
		return nil, fmt.Errorf("showKey: malformed data received %v", resp)
	}

	var result SSHKey
	if err := mapstructure.Decode(ssh_key, &result); err != nil {
		return nil, err
	}

	return &result, nil
}

// Keys returns all available public SSH Keys
func (d *DigitalOcean) Keys() (SSHKeys, error) {
	resp, err := digitalocean.NewRequest(*d.Client, "ssh_keys", url.Values{})
	if err != nil {
		return nil, err
	}

	var result SSHKeys
	if err := mapstructure.Decode(resp["ssh_keys"], &result); err != nil {
		return nil, err
	}

	return result, nil
}
