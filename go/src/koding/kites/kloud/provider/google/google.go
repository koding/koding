package google

import (
	"errors"
	"fmt"

	"koding/kites/kloud/stack"
	"koding/kites/kloud/stack/provider"
)

var p = &provider.Provider{
	Name:         "google",
	ResourceName: "compute_instance",
	Machine:      newMachine,
	Stack:        nil,
	Schema: &provider.Schema{
		NewCredential: newCredential,
		NewBootstrap:  newBootstrap,
		NewMetadata:   nil,
	},
}

func init() {
	provider.Register(p)
}

// todo
func newMachine(bm *provider.BaseMachine) (provider.Machine, error) {
	m := &Machine{BaseMachine: bm}
	return m, nil
}

func newCredential() interface{} {
	return &Cred{}
}

func newBootstrap() interface{} {
	return &Bootstrap{}
}

// Region represents google's geographical region code.
type Region string

var regions = []Region{
	"asia-east1",
	"europe-west1",
	"us-central1",
	"us-east1",
	"us-west1",
}

// Enum returns all available regions for "google" provider.
func (Region) Enum() (rs []interface{}) {
	for _, region := range regions {
		rs = append(rs, region)
	}
	return rs
}

// Valid checks if stored region code is available in GCP.
func (r Region) Valid() error {
	if r == "" {
		return fmt.Errorf("region name is not set")
	}

	for _, region := range regions {
		if r == region {
			return nil
		}
	}

	return fmt.Errorf("unknown region name: %v", r)
}

// Cred represents jCredentialDatas.meta for "google" provider.
type Cred struct {
	Credentials string `json:"credentials" bson:"credentials" hcl:"credentials" kloud:",secret"`
	Project     string `json:"project" bson:"project" hcl:"project" kloud:",secret"`
	Region      Region `json:"region" bson:"region" hcl:"region"`
}

var _ stack.Validator = (*Cred)(nil)

// Valid implements the kloud.Validator interface.
func (c *Cred) Valid() error {
	if c.Credentials == "" {
		return errors.New("google: JSON credentials content is empty")
	}
	if c.Project == "" {
		return errors.New("google: project name is empty")
	}

	return c.Region.Valid()
}

type Bootstrap struct {
	Address  string `json:"address" bson:"address" hcl:"address"`
	SelfLink string `json:"self_link" bson:"self_link" hcl:"self_link"`
}

var _ stack.Validator = (*Bootstrap)(nil)

func (b *Bootstrap) Valid() error {
	if b.Address == "" {
		return errors.New(`bootstrap value for "address" is empty`)
	}
	if b.SelfLink == "" {
		return errors.New(`bootstrap value for "self_block" is empty`)
	}
	return nil
}
