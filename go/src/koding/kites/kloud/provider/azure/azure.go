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

var p = &provider.Provider{
	Name:         "azure",
	ResourceName: "instance",
	Machine:      newMachine,
	Stack:        newStack,
	Schema: &provider.Schema{
		NewCredential: newCredential,
		NewBootstrap:  newBootstrap,
		NewMetadata:   newMetadata,
	},
}

func init() {
	provider.Register(p)
}

func newMachine(bm *provider.BaseMachine) (provider.Machine, error) {
	m := &Machine{BaseMachine: bm}
	cred := m.Cred()

	c, err := management.ClientFromPublishSettingsDataWithConfig(cred.PublishSettings, cred.SubscriptionID, management.DefaultConfig())
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
		meta.Location = cred.Location
	}

	return meta
}

type PublishData struct {
	Subscriptions []Subscription `xml:"PublishProfile>Subscription"`
}

type Subscription struct {
	ID string `xml:"Id,attr"`
}

// Cred represents jCredentialDatas.meta for "azure" provider.
type Cred struct {
	// Credentials.
	PublishSettings []byte `json:"publish_settings" bson:"publish_settings" hcl:"publish_settings"` // required
	SubscriptionID  string `json:"subscription_id,omitempty" bson:"subscription_id,omitempty" hcl:"subscription_id"`
	Location        string `json:"location,omitempty" bson:"location,omitempty" hcl:"location"` // by default "East US 2"
}

var _ stack.Validator = (*Cred)(nil)

func (meta *Cred) PublishData() (*PublishData, error) {
	var pb PublishData

	if err := xml.Unmarshal(meta.PublishSettings, &pb); err != nil {
		return nil, err
	}

	if len(pb.Subscriptions) == 0 {
		return nil, errors.New("no subscriptions found in the publish settings file")
	}

	return &pb, nil
}

// Valid implements the kloud.Validator interface.
func (meta *Cred) Valid() error {
	if meta.Location == "" {
		meta.Location = "East US 2"
	}
	if len(meta.PublishSettings) == 0 {
		return errors.New("publish settings are emtpty or missing")
	}

	pb, err := meta.PublishData()
	if err != nil {
		return err
	}

	// If SubscriptionID was not explicitely provided and the publish
	// settings file contains only one subscription, we default to it.
	if meta.SubscriptionID == "" {
		if n := len(pb.Subscriptions); n != 1 {
			return fmt.Errorf("publish settings contain %d subscriptions, please specify which one to use", n)
		}

		return nil
	}

	var found bool
	for _, sub := range pb.Subscriptions {
		if sub.ID == meta.SubscriptionID {
			found = true
			break
		}
	}

	if !found {
		return errors.New("specified subscription ID does not exist")
	}

	return nil
}

type Bootstrap struct {
	AddressSpace     string `json:"address_space,omitempty" bson:"address_space,omitempty" hcl:"address_space"`                      // by default "10.0.0.0/16"
	Storage          string `json:"storage,omitempty" bson:"storage,omitempty" hcl:"storage"`                                        // by default "Standard_LRS"
	StorageServiceID string `json:"storage_service_name,omitempty" bson:"storage_service_name,omitempty" hcl:"storage_service_name"` // unique Azure-wide

	// Bootstrap metadata.
	HostedServiceID  string `json:"hosted_service_name,omitempty" bson:"hosted_service_name,omitempty" hcl:"hosted_service_name"` // unique Azure-wide
	SecurityGroupID  string `json:"security_group,omitempty" bson:"security_group,omitempty" hcl:"security_group"`
	VirtualNetworkID string `json:"virtual_network,omitempty" bson:"virtual_network,omitempty" hcl:"virtual_network"`
	SubnetName       string `json:"subnet,omitempty" bson:"subnet,omitempty" hcl:"subnet"`
}

var _ stack.Validator = (*Bootstrap)(nil)

func (b *Bootstrap) Valid() error {
	if b.AddressSpace == "" {
		b.AddressSpace = "10.0.0.0/16"
	}
	if b.Storage == "" {
		b.Storage = "Standard_LRS"
	}
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

type Meta struct {
	AlwaysOn        bool   `bson:"alwaysOn"`
	InstanceID      string `json:"instanceId" bson:"instanceId"`
	HostedServiceID string `json:"hostedServiceId" bson:"hostedServiceId"`
	InstanceType    string `json:"instance_type" bson:"instance_type"`
	Location        string `json:"location" bson:"location"`
	StorageSize     int    `json:"storage_size" bson:"storage_size"`
}

func (mt *Meta) Valid() error {
	if mt.InstanceID == "" {
		return errors.New("invalid empty instance ID")
	}

	if mt.HostedServiceID == "" {
		return errors.New("invalid hosted service ID")
	}

	return nil
}
