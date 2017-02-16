package do

import (
	"errors"
	"fmt"
	"strconv"

	"koding/kites/kloud/stack"
	"koding/kites/kloud/stack/provider"
)

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

// RegionType represents a DigitalOcean region
type RegionType string

var _ stack.Enumer = RegionType("")

var Regions = []stack.Enum{
	{Title: "Amsterdam 1", Value: "ams1"},
	{Title: "Amsterdam 2", Value: "ams2"},
	{Title: "Amsterdam 3", Value: "ams3"},
	{Title: "Bangalore 1", Value: "blr1"},
	{Title: "France 1", Value: "fra1"},
	{Title: "London 1", Value: "lon1"},
	{Title: "New York 1", Value: "nyc1"},
	{Title: "New York 2", Value: "nyc2"},
	{Title: "New York 3", Value: "nyc3"},
	{Title: "San Francisco 1", Value: "sfo1"},
	{Title: "San Francisco 2", Value: "sfo2"},
	{Title: "Singapore 1", Value: "sgp1"},
	{Title: "Toronto 1", Value: "tor1"},
}

func (RegionType) Enums() []stack.Enum { return Regions }

// Metadata represent the data that is stored on Koding's DB storage
type Metadata struct {
	DropletID int        `json:"droplet_id" bson:"droplet_id" hcl:"droplet_id"`
	Region    RegionType `json:"region" bson:"region" hcl:"region"`
	Size      string     `json:"size" bson:"size" hcl:"size"`
	Image     string     `json:"image" bson:"image" hcl:"image"`
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
		Region: RegionType(m.Attributes["region"]),
	}

	if id, err := strconv.Atoi(m.Attributes["id"]); err == nil {
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

	if err := m.Region.Valid(); err != nil {
		return err
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

// Valid implements the stack.Validator interface.
func (r RegionType) Valid() error {
	for _, region := range Regions {
		if r == RegionType(region.Value.(string)) {
			return nil
		}
	}
	return fmt.Errorf("region %q does not exist", r)
}
