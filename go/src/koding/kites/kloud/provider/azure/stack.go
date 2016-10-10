package azure

import (
	"encoding/xml"
	"errors"
	"fmt"

	"koding/kites/kloud/provider"
	"koding/kites/kloud/stack"
	"koding/kites/kloud/stackplan"

	"golang.org/x/net/context"
)

type PublishData struct {
	Subscriptions []Subscription `xml:"PublishProfile>Subscription"`
}

type Subscription struct {
	ID string `xml:"Id,attr"`
}

// Cred represents jCredentialDatas.meta for "azure" provider.
type Cred struct {
	// Credentials.
	PublishSettings  []byte `json:"publish_settings" bson:"publish_settings" hcl:"publish_settings"` // required
	SubscriptionID   string `json:"subscription_id,omitempty" bson:"subscription_id,omitempty" hcl:"subscription_id"`
	Location         string `json:"location,omitempty" bson:"location,omitempty" hcl:"location"`                                     // by default "East US 2"
	AddressSpace     string `json:"address_space,omitempty" bson:"address_space,omitempty" hcl:"address_space"`                      // by default "10.0.0.0/16"
	Storage          string `json:"storage,omitempty" bson:"storage,omitempty" hcl:"storage"`                                        // by default "Standard_LRS"
	StorageServiceID string `json:"storage_service_name,omitempty" bson:"storage_service_name,omitempty" hcl:"storage_service_name"` // unique Azure-wide

	// Bootstrap metadata.
	HostedServiceID  string `json:"hosted_service_name,omitempty" bson:"hosted_service_name,omitempty" hcl:"hosted_service_name"` // unique Azure-wide
	SecurityGroupID  string `json:"security_group,omitempty" bson:"security_group,omitempty" hcl:"security_group"`
	VirtualNetworkID string `json:"virtual_network,omitempty" bson:"virtual_network,omitempty" hcl:"virtual_network"`
	SubnetName       string `json:"subnet,omitempty" bson:"subnet,omitempty" hcl:"subnet"`
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

	if meta.Location == "" {
		meta.Location = "East US 2"
	}

	if meta.AddressSpace == "" {
		meta.AddressSpace = "10.0.0.0/16"
	}

	if meta.Storage == "" {
		meta.Storage = "Standard_LRS"
	}

	return nil
}

func (meta *Cred) BootstrapValid() error {
	if meta.HostedServiceID == "" {
		return errors.New("hosted service ID is empty or missing")
	}
	if meta.StorageServiceID == "" {
		return errors.New("storage service ID is empty or missing")
	}
	if meta.SecurityGroupID == "" {
		return errors.New("security group ID is empty or missing")
	}
	if meta.VirtualNetworkID == "" {
		return errors.New("virtual network ID is empty or missing")
	}
	if meta.SubnetName == "" {
		return errors.New("subnet name is empty or missing")
	}
	return nil
}

func (meta *Cred) ResetBootstrap() {
	meta.HostedServiceID = ""
	meta.StorageServiceID = ""
	meta.SecurityGroupID = ""
	meta.VirtualNetworkID = ""
	meta.SubnetName = ""
}

// Stack implements the kloud.StackProvider interface.
type Stack struct {
	*provider.BaseStack

	p *stackplan.Planner
	c *stackplan.Credential

	// The following fields are set by buildResources method:
	ids     stackplan.KiteMap
	klients map[string]*stackplan.DialState
}

// Ensure Provider implements the kloud.StackProvider interface.
//
// StackProvider is an interface for team kloud API.
var _ stack.Provider = (*Provider)(nil)

// Stack gives a kloud.Stacker value that implements stack
// methods for the AWS cloud.
func (p *Provider) Stack(ctx context.Context) (stack.Stack, error) {
	bs, err := p.BaseStack(ctx)
	if err != nil {
		return nil, err
	}

	s := &Stack{
		BaseStack: bs,
		p: &stackplan.Planner{
			Provider:     "azure",
			ResourceType: "instance",
		},
	}

	bs.BuildResources = s.buildResources
	bs.WaitResources = s.waitResources
	bs.UpdateResources = s.updateResources

	return s, nil
}

func (s *Stack) BuildCredentials(group string, creds []string) error {
	if err := s.Builder.BuildCredentials(s.Req.Method, s.Req.Username, group, creds); err != nil {
		return err
	}

	for _, cred := range s.Builder.Credentials {
		if cred.Provider == s.p.Provider {
			s.c = cred

			meta := s.Cred()

			if meta == nil {
				continue
			}

			if err := meta.Valid(); err != nil {
				return err
			}

			break
		}
	}

	return nil
}

func (s *Stack) Cred() *Cred {
	if s.c == nil {
		return nil
	}

	c, ok := s.c.Meta.(*Cred)
	if !ok {
		return nil
	}

	return c
}
