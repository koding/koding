package do

import (
	"errors"
	"fmt"
	"strconv"

	"koding/kites/kloud/stack"
	"koding/kites/kloud/stack/provider"
)

// validRegions shows the valid DigitalOcean regions can be obtained via:
// https://developers.digitalocean.com/documentation/v2/#list-all-regions
var validRegions = []string{
	"ams1",
	"ams2",
	"ams3",
	"blr1",
	"fra1",
	"lon1",
	"nyc1",
	"nyc2",
	"nyc3",
	"sfo1",
	"sfo2",
	"sgp1",
	"tor1",
}

// Credential stores the necessary credentials needed to interact with
// DigitalOcean API
type Credential struct {
	AccessToken string `json:"access_token" bson:"access_token" hcl:"access_token"`
}

// Bootstrap represent the data to bootstrap the DigitalOcean environment
type Bootstrap struct {
	// More info about SSH Key data on DigitalOcean can be found here:
	// https://developers.digitalocean.com/documentation/v2/#ssh-keys
	// KeyName represents the SSH Key name
	KeyName string `json:"key_name" bson:"key_name" hcl:"key_name"`

	// KeyID is a uniqe identification number for
	KeyID string `json:"key_id" bson:"key_id" hcl:"key_id"`

	// KeyFingerprint contains the fingerprint value that is generated from the
	// public key
	KeyFingerprint string `json:"key_fingerprint" bson:"key_fingerprint" hcl:"key_fingerprint"`
}

// Region represents a DigitalOcean region
type Region string

// Metadata represent the data that is stored on Koding's DB storage
type Metadata struct {
	DropletID int    `json:"droplet_id" bson:"droplet_id" hcl:"droplet_id"`
	Region    Region `json:"region" bson:"region" hcl:"region"`
	Size      string `json:"size" bson:"size" hcl:"size"`
	Image     string `json:"image" bson:"image" hcl:"image"`
}

func newSchema() *provider.Schema {
	return &provider.Schema{
		NewCredential: newCredential,
		NewBootstrap:  newBootstrap,
		NewMetadata:   newMetadata,
	}
}

func newCredential() interface{} {
	return &Credential{}
}

func newBootstrap() interface{} {
	return &Bootstrap{}
}

func newMetadata(m *stack.Machine) interface{} {
	if m == nil {
		return &Metadata{}
	}

	meta := &Metadata{
		Size:   m.Attributes["size"],
		Image:  m.Attributes["image"],
		Region: Region(m.Attributes["region"]),
	}

	if id, err := strconv.Atoi(m.Attributes["droplet_id"]); err == nil {
		meta.DropletID = id
	}
	return meta
}

// Valid implements stack.Validator
func (c *Credential) Valid() error {
	if c.AccessToken == "" {
		return errors.New("access_token is empty")
	}

	return nil
}

// Valid implements stack.Validator
func (m *Metadata) Valid() error {
	if m.DropletID == 0 {
		return errors.New("droplet ID cannot be empty")
	}

	if m.Size == "" {
		return errors.New("size cannot be empty")
	}

	if m.Region == "" {
		return errors.New("region cannot be empty")
	}

	if !m.Region.isValid() {
		return fmt.Errorf("region %q is not valid. Valid regions can be one of the following: %v",
			m.Region, validRegions)
	}

	if m.Image == "" {
		return errors.New("image cannot be empty")
	}

	return nil
}

// Valid implements stack.Validator
func (b *Bootstrap) Valid() error {
	if b.KeyName == "" {
		return errors.New("key name cannot be empty")
	}

	if b.KeyID == "" {
		return errors.New("key id cannot be empty")
	}

	if _, err := strconv.Atoi(b.KeyID); err != nil {
		return fmt.Errorf("key id should be an integer, have: %q", b.KeyID)
	}

	if b.KeyFingerprint == "" {
		return errors.New("key fingerprint cannot be empty")
	}

	return nil
}

// isValid checks whether the given region is valid or not
func (r Region) isValid() bool {
	for _, validRegion := range validRegions {
		if validRegion == string(r) {
			return true
		}
	}
	return false
}

// Enum implements the stack.Enumer interface
func (Region) Enum() []interface{} {
	// TODO: check whether the valid regions have metadata listed as their
	// features and only show those regions, because User Data is currently
	// only available in regions with metadata listed in their features.
	regions := make([]interface{}, len(validRegions))

	for i, region := range validRegions {
		regions[i] = region
	}

	return regions
}
