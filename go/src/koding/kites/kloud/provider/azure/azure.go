package azure

import (
	"encoding/xml"
	"errors"
	"fmt"

	"koding/kites/kloud/stack"
	"koding/kites/kloud/stack/provider"

	"github.com/Azure/azure-sdk-for-go/management"
	vm "github.com/Azure/azure-sdk-for-go/management/virtualmachine"
)

var Provider = &provider.Provider{
	Name:         "azure",
	ResourceName: "instance",
	Userdata:     "custom_data",
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

func newMachine(bm *provider.BaseMachine) (provider.Machine, error) {
	m := &Machine{BaseMachine: bm}
	cred := m.Cred()

	c, err := management.ClientFromPublishSettingsDataWithConfig([]byte(cred.PublishSettings), cred.SubscriptionID, management.DefaultConfig())
	if err != nil {
		return nil, err
	}

	vmclient := vm.NewClient(c)

	m.AzureClient = c
	m.AzureVMClient = &vmclient

	return m, nil
}

func newStack(bs *provider.BaseStack) (provider.Stack, error) {
	return &Stack{BaseStack: bs}, nil
}

func newCredential() interface{} {
	return &Cred{}
}

func newBootstrap() interface{} {
	return &Bootstrap{}
}

func newMetadata(m *stack.Machine) interface{} {
	if m == nil {
		return &Meta{}
	}

	meta := &Meta{
		InstanceID:      m.Attributes["id"],
		HostedServiceID: m.Attributes["hosted_service_name"],
		InstanceType:    m.Attributes["size"],
	}

	if cred, ok := m.Credential.Credential.(*Cred); ok {
		meta.Location = string(cred.Location)
	}

	return meta
}

type PublishData struct {
	Subscriptions []Subscription `xml:"PublishProfile>Subscription"`
}

type Subscription struct {
	ID string `xml:"Id,attr"`
}

type (
	StorageType  string
	LocationType string
)

var (
	_ stack.Enumer = StorageType("")
	_ stack.Enumer = LocationType("")
)

var (
	Storages = []stack.Enum{
		{Title: "Locally redundant storage (LRS)", Value: "Standard_LRS"},
		{Title: "Zone-redundant storage (ZRS)", Value: "Standard_ZRS"},
		{Title: "Geo-redundant storage (GRS)", Value: "Standard_GRS"},
		{Title: "Read-access geo-redundant storage (RA-GRS)", Value: "Standard_RAGRS"},
		{Title: "Premium Locally redundant storage (P_LRS)", Value: "Premium_LRS"},
	}

	Locations = []stack.Enum{
		{Title: "East US", Value: "East US"},
		{Title: "East US 2", Value: "East US 2"},
		{Title: "West US", Value: "West US"},
		{Title: "Central US", Value: "Central US"},
		{Title: "South Central US", Value: "South Central US"},
		{Title: "North Europe", Value: "North Europe"},
		{Title: "West Europe", Value: "West Europe"},
		{Title: "East Asia", Value: "East Asia"},
		{Title: "Southeast Asia", Value: "Southeast Asia"},
		{Title: "Japan East", Value: "Japan East"},
		{Title: "Japan West", Value: "Japan West"},
		{Title: "North Central US", Value: "North Central US"},
		{Title: "Brazil South", Value: "Brazil South"},
	}
)

func (StorageType) Enums() []stack.Enum  { return Storages }
func (LocationType) Enums() []stack.Enum { return Locations }

// Cred represents jCredentialDatas.meta for "azure" provider.
type Cred struct {
	PublishSettings  string       `json:"publish_settings" bson:"publish_settings" hcl:"publish_settings"`                  // required
	SubscriptionID   string       `json:"subscription_id,omitempty" bson:"subscription_id,omitempty" hcl:"subscription_id"` // required if PublishSettings contains multiple subscriptions
	Location         LocationType `json:"location,omitempty" bson:"location,omitempty" hcl:"location"`                      // by default "East US 2"
	Storage          StorageType  `json:"storage,omitempty" bson:"storage,omitempty" hcl:"storage"`                         // by default "Standard_LRS"
	SSHKeyThumbprint string       `json:"ssh_key_thumbprint,omitempty" bson:"ssh_key_thumbprint" hcl:"ssh_key_thumbprint"`
	Password         string       `json:"password" bson:"password" hcl:"password"`
}

var _ stack.Validator = (*Cred)(nil)

// PublishData parses PublishSettings field and gives metadata that
// describes subscriptions.
func (meta *Cred) PublishData() (*PublishData, error) {
	var pb PublishData

	if err := xml.Unmarshal([]byte(meta.PublishSettings), &pb); err != nil {
		return nil, err
	}

	if len(pb.Subscriptions) == 0 {
		return nil, errors.New("no subscriptions found in the publish settings file")
	}

	return &pb, nil
}

// Valid implements the stack.Validator interface.
func (meta *Cred) Valid() error {
	if meta.Location == "" {
		meta.Location = "East US 2"
	}

	if meta.Storage == "" {
		meta.Storage = "Standard_LRS"
	}

	if len(meta.PublishSettings) == 0 {
		return errors.New("publish settings are emtpty or missing")
	}

	pb, err := meta.PublishData()
	if err != nil {
		return err
	}

	// If SubscriptionID was not explicitly provided and the publish
	// settings file contains only one subscription, we default to it.
	if meta.SubscriptionID == "" {
		if n := len(pb.Subscriptions); n != 1 {
			return fmt.Errorf("publish settings contain %d subscriptions, please specify which one to use", n)
		}

		return nil
	}

	for _, sub := range pb.Subscriptions {
		if sub.ID == meta.SubscriptionID {
			return nil
		}
	}

	return errors.New("specified subscription ID does not exist")
}

// Bootstrap represents bootstrapping metadata for a single Azure stack.
type Bootstrap struct {
	AddressSpace     string `json:"address_space,omitempty" bson:"address_space,omitempty" hcl:"address_space"`                      // by default "10.0.0.0/16"
	StorageServiceID string `json:"storage_service_name,omitempty" bson:"storage_service_name,omitempty" hcl:"storage_service_name"` // unique Azure-wide

	// Bootstrap metadata.
	HostedServiceID  string `json:"hosted_service_name,omitempty" bson:"hosted_service_name,omitempty" hcl:"hosted_service_name"` // unique Azure-wide
	SecurityGroupID  string `json:"security_group,omitempty" bson:"security_group,omitempty" hcl:"security_group"`                // security group for the stack
	VirtualNetworkID string `json:"virtual_network,omitempty" bson:"virtual_network,omitempty" hcl:"virtual_network"`             // vlan for all the instances within stack
	SubnetName       string `json:"subnet,omitempty" bson:"subnet,omitempty" hcl:"subnet"`                                        // name of default subnet that belongs to vlan
}

var _ stack.Validator = (*Bootstrap)(nil)

// Valid implements the stack.Validator interface.
func (b *Bootstrap) Valid() error {
	b.AddressSpace = b.addressSpace()

	if b.HostedServiceID == "" {
		return errors.New("hosted service ID is empty or missing")
	}
	if b.StorageServiceID == "" {
		return errors.New("storage service ID is empty or missing")
	}
	if b.SecurityGroupID == "" {
		return errors.New("security group ID is empty or missing")
	}
	if b.VirtualNetworkID == "" {
		return errors.New("virtual network ID is empty or missing")
	}
	if b.SubnetName == "" {
		return errors.New("subnet name is empty or missing")
	}
	return nil
}

func (b *Bootstrap) addressSpace() string {
	if b.AddressSpace != "" {
		return b.AddressSpace
	}

	return "10.0.0.0/16"
}

// Meta represents a metadata for a single Azure machine.
type Meta struct {
	AlwaysOn        bool   `json:"alwaysOn" bson:"alwaysOn"`               // whether machine should not be stopped after 1h
	InstanceID      string `json:"instanceId" bson:"instanceId"`           // Azure's instance ID
	HostedServiceID string `json:"hostedServiceId" bson:"hostedServiceId"` // Azure's service ID
	InstanceType    string `json:"instance_type" bson:"instance_type"`     // type of the instance
	Location        string `json:"location" bson:"location"`               // datacenter of the instance
	StorageSize     int    `json:"storage_size" bson:"storage_size"`       // storage size of the instance
}

// Valid implements the stack.Validator interface.
func (mt *Meta) Valid() error {
	if mt.InstanceID == "" {
		return errors.New("invalid empty instance ID")
	}

	if mt.HostedServiceID == "" {
		return errors.New("invalid hosted service ID")
	}

	return nil
}
