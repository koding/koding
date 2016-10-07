package softlayer

import (
	"errors"
)

// Defines parameters required for provisioning against Softlayer API
// Persisted to Koding safe store
type Credential struct {
	Username   string `json:"username"`
	ApiKey string `json:"api_key" kloud: ",secret"`
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
	KeyFingerprint string `json:"key_fingerprint" bson:"key_fingerprint" hcl:"key_fingerprint"`
}

// Defines metadata of a single Softlayer instance
// Belongs to a Softlayer instance
// NOTE: useful for storing things to be referenced in Machine funcs
type Metadata struct {
	ID string `bson:"id"`
}
