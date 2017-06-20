package google

import (
	"encoding/json"
	"errors"
	"fmt"
	"strconv"
	"strings"

	"koding/kites/kloud/stack"
	"koding/kites/kloud/stack/provider"

	"golang.org/x/net/context"
	"golang.org/x/oauth2/google"
	compute "google.golang.org/api/compute/v1"
)

// Provider is a GCE kloud provider.
var Provider = &provider.Provider{
	Name:         "google",
	ResourceName: "compute_instance",
	Userdata:     "user-data",
	UserdataPath: []string{"google_compute_instance", "*", "metadata", "user-data"},
	Machine:      newMachine,
	Stack:        newStack,
	Schema: &provider.Schema{
		NewCredential: newCredential,
		NewBootstrap:  newBootstrap,
		NewMetadata:   newMetadata,
	},
}

func init() {
	provider.Register(Provider)
}

// RegionType represents google's geographical region code.
type RegionType string

var _ stack.Enumer = RegionType("")

var Regions = []stack.Enum{
	{Title: "Asia West 1", Value: "asia-east1"},
	{Title: "Europte West 1", Value: "europe-west1"},
	{Title: "US Central 1", Value: "us-central1"},
	{Title: "US East 1", Value: "us-east1"},
	{Title: "US West 1", Value: "us-west1"},
}

// Enum returns all available regions for "google" provider.
func (RegionType) Enums() []stack.Enum { return Regions }

// Valid checks if stored region code is available in GCP.
func (r RegionType) Valid() error {
	if r == "" {
		return fmt.Errorf("region name is not set")
	}

	for _, region := range Regions {
		if r == RegionType(region.Value.(string)) {
			return nil
		}
	}

	return fmt.Errorf("region %q does not exist", r)
}

// Cred represents jCredentialDatas.meta for "google" provider.
type Cred struct {
	Credentials string     `json:"credentials" bson:"credentials" hcl:"credentials" kloud:",secret"`
	Project     string     `json:"project" bson:"project" hcl:"project"`
	Region      RegionType `json:"region" bson:"region" hcl:"region"`
}

var _ stack.Validator = (*Cred)(nil)

func newCredential() interface{} {
	return &Cred{}
}

func (c *Cred) Valid() error {
	if c.Credentials == "" {
		return errors.New(`cred value for "credentials" is empty`)
	}
	if c.Project == "" {
		return errors.New(`cred value for "project" is empty`)
	}

	// This variable is used to check most important JSON-credential fields.
	var acckey = struct {
		Typ        string `json:"type"`
		ProjectID  string `json:"project_id"`
		PrivateKey string `json:"private_key"`
	}{}

	if err := json.Unmarshal([]byte(c.Credentials), &acckey); err != nil {
		return fmt.Errorf("credentials are invalid: %s", err)
	}

	if acckey.Typ != "service_account" {
		return fmt.Errorf("account type field is invalid: %s", acckey.Typ)
	}

	if acckey.ProjectID == "" {
		return errors.New("account project_id field is missing or empty")
	}

	if !strings.HasPrefix(acckey.PrivateKey, "-----BEGIN PRIVATE KEY-----") {
		return errors.New("account private_key field format is invalid")
	}

	return c.Region.Valid()
}

func (c *Cred) ComputeService() (*compute.Service, error) {
	cfg, err := google.JWTConfigFromJSON([]byte(c.Credentials), compute.ComputeScope)
	if err != nil {
		return nil, err
	}

	// TODO(rjeczalik): requires testing (also pass (*BaseStack).Debug)
	// ctx := context.WithValue(context.Background(), oauth2.HTTPClient, httputil.Client(false))
	ctx := context.Background()

	return compute.New(cfg.Client(ctx))
}

type Bootstrap struct {
	KodingNetworkID string `json:"koding_network_id" bson:"koding_network_id" hcl:"koding_network_id"`
}

var _ stack.Validator = (*Bootstrap)(nil)

func newBootstrap() interface{} {
	return &Bootstrap{}
}

func (b *Bootstrap) Valid() error {
	if b.KodingNetworkID == "" {
		return errors.New(`bootstrap value for "koding_network_id" is empty`)
	}
	return nil
}

type Meta struct {
	Name        string     `json:"name" bson:"name" hcl:"name"`
	Region      RegionType `json:"region" bson:"region" hcl:"region"`
	Zone        string     `json:"zone" bson:"zone" hcl:"zone"`
	Image       string     `json:"image" bson:"image" hcl:"image"`
	StorageSize int        `json:"storage_size" bson:"storage_size" hcl:"storage_size"`
	MachineType string     `json:"machine_type" bson:"machine_type" hcl:"machine_type"`
}

var _ stack.Validator = (*Meta)(nil)

func newMetadata(m *stack.Machine) interface{} {
	if m == nil {
		return &Meta{}
	}

	meta := &Meta{
		Name:        m.Attributes["name"],
		Zone:        m.Attributes["zone"],
		Image:       m.Attributes["disk.0.image"],
		MachineType: m.Attributes["machine_type"],
	}

	if n, err := strconv.Atoi(m.Attributes["disk.0.size"]); err == nil {
		meta.StorageSize = n
	}

	if cred, ok := m.Credential.Credential.(*Cred); ok {
		meta.Region = cred.Region
	}

	return meta
}

func (m *Meta) Valid() error {
	if m.Name == "" {
		return errors.New(`metadata value for "name" is empty`)
	}
	if err := m.Region.Valid(); err != nil {
		return fmt.Errorf(`metadata region is unknown: %v`, err)
	}
	if m.Zone == "" {
		return errors.New(`metadata value for "zone" is empty`)
	}
	if m.Image == "" {
		return errors.New(`metadata value for "image" is empty`)
	}
	if m.MachineType == "" {
		return errors.New(`metadata value for "machie_type" is empty`)
	}

	return nil
}
