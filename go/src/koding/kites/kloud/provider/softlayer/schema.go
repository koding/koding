package softlayer

import (
	"errors"
)

// Defines a SoftLayer region code
type Region string

// Defines parameters required for provisioning against Softlayer API
type Credential struct {
	Username string `json:"username" bson:"username" hcl:"username"`
	ApiKey   string `json:"api_key" bson:"api_key" hcl:"api_key" kloud:",secret"`
}

func (c *Credential) Valid() error {
	if c.Username == "" {
		return errors.New("Credential is missing Username property")
	}

	if c.ApiKey == "" {
		return errors.New("Credential is missing ApiKey property")
	}

	return nil
}

// Defines the `output` variables of bootstrapTemplate
// Belongs to a Credential value in Koding safe store
// Bootstrapped properties are shared among instances.
type Bootstrap struct {
	KeyID string `json:"key_id" bson:"key_id" hcl:"key_id"`
}

// Defines metadata of a single Softlayer instance
// Belongs to a Softlayer instance
// NOTE: useful for storing things to be referenced in Machine funcs
type Metadata struct {
	Id int `json:"id" bson:"id" hcl:"id"`
}
