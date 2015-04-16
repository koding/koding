package digitalocean

import (
	"fmt"
	"strconv"
)

// SSHKey is used to represent a retrieved SSH key.
type SSHKey struct {
	Id          int64  `json:"id"`
	Name        string `json:"name"`
	Fingerprint string `json:"fingerprint"`
	PublicKey   string `json:"public_key"`
}

type sshKeyResponse struct {
	SSHKey SSHKey `json:"ssh_key"`
}

// CreateSSHKey contains the request parameters to register a new SSH key.
type CreateSSHKey struct {
	Name      string `json:"name,omitempty"`
	PublicKey string `json:"public_key,omitempty"`
}

// StringId returns the slug for the key
func (k *SSHKey) StringId() string {
	return strconv.FormatInt(k.Id, 10)
}

// CreateSSHKey creates an SSH key from the parameters specified and returns an
// error if it fails. If no error and the SSH key is returned, it was
// succesfully created.
func (c *Client) CreateSSHKey(opts *CreateSSHKey) (string, error) {
	req, err := c.NewRequest(opts, "POST", "/account/keys")

	if err != nil {
		return "", err
	}

	resp, err := checkResp(c.Http.Do(req))

	if err != nil {
		return "", fmt.Errorf("Error creating SSH key: %s", err)
	}

	sshKey := new(sshKeyResponse)

	err = decodeBody(resp, &sshKey)

	if err != nil {
		return "", fmt.Errorf("Error parsing SSH key response: %s", err)
	}

	// The request was successful
	return sshKey.SSHKey.StringId(), nil
}

// RetrieveSSHKey gets an SSH key by the ID specified and returns a SSHKey and
// an error. An error will be returned for failed requests with a nil SSHKey.
func (c *Client) RetrieveSSHKey(id string) (SSHKey, error) {
	req, err := c.NewRequest(nil, "GET", fmt.Sprintf("/account/keys/%s", id))

	if err != nil {
		return SSHKey{}, err
	}

	resp, err := checkResp(c.Http.Do(req))
	if err != nil {
		return SSHKey{}, fmt.Errorf("Error retreiving SSH key: %s", err)
	}

	sshKey := new(sshKeyResponse)

	err = decodeBody(resp, &sshKey)

	if err != nil {
		return SSHKey{}, fmt.Errorf("Error decoding droplet response: %s", err)
	}

	// The request was successful
	return sshKey.SSHKey, nil
}

// RenameSSHKey renames an SSH key to the name specified
func (c *Client) RenameSSHKey(id string, name string) error {
	params := &CreateSSHKey{
		Name: name,
	}

	req, err := c.NewRequest(params, "PUT", fmt.Sprintf("/account/keys/%s", id))

	if err != nil {
		return err
	}

	_, err = checkResp(c.Http.Do(req))

	if err != nil {
		return fmt.Errorf("Error updating record: %s", err)
	}

	// The request was successful
	return nil
}

// DestroySSHKey destroys an SSH key by the ID specified and returns an error if
// it fails. If no error is returned, the key was succesfully destroyed.
func (c *Client) DestroySSHKey(id string) error {
	req, err := c.NewRequest(nil, "DELETE", fmt.Sprintf("/account/keys/%s", id))

	if err != nil {
		return err
	}

	_, err = checkResp(c.Http.Do(req))

	if err != nil {
		return fmt.Errorf("Error destroying SSH key: %s", err)
	}

	// The request was successful
	return nil
}
