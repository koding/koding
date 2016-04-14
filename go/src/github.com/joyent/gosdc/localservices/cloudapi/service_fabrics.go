package cloudapi

import (
	"fmt"
	"math/rand"

	"github.com/joyent/gosdc/cloudapi"
	"github.com/joyent/gosdc/localservices"
)

func (c *CloudAPI) getFabricWrapper(vlanID int16) (*fabricVLAN, error) {
	vlan, present := c.fabricVLANs[vlanID]
	if !present {
		return nil, fmt.Errorf("VLAN %d not found", vlanID)
	}

	return vlan, nil
}

// ListFabricVLANs lists VLANs
func (c *CloudAPI) ListFabricVLANs() ([]cloudapi.FabricVLAN, error) {
	out := []cloudapi.FabricVLAN{}
	for _, vlan := range c.fabricVLANs {
		out = append(out, vlan.FabricVLAN)
	}

	return out, nil
}

// GetFabricVLAN retrieves a single VLAN by ID
func (c *CloudAPI) GetFabricVLAN(vlanID int16) (*cloudapi.FabricVLAN, error) {
	vlan, err := c.getFabricWrapper(vlanID)
	if err != nil {
		return nil, err
	}

	return &vlan.FabricVLAN, nil
}

// CreateFabricVLAN creates a new VLAN with the specified options
func (c *CloudAPI) CreateFabricVLAN(vlan cloudapi.FabricVLAN) (*cloudapi.FabricVLAN, error) {
	id := int16(rand.Intn(4095 + 1))
	vlan.Id = id

	c.fabricVLANs[id] = &fabricVLAN{
		FabricVLAN: vlan,
		Networks:   make(map[string]*cloudapi.FabricNetwork),
	}

	return &vlan, nil
}

// UpdateFabricVLAN updates a given VLAN with new fields
func (c *CloudAPI) UpdateFabricVLAN(new cloudapi.FabricVLAN) (*cloudapi.FabricVLAN, error) {
	current, err := c.GetFabricVLAN(new.Id)
	if err != nil {
		return nil, err
	}

	current.Name = new.Name
	current.Description = new.Description

	return current, nil
}

// DeleteFabricVLAN delets a given VLAN as specified by ID
func (c *CloudAPI) DeleteFabricVLAN(vlanID int16) error {
	_, present := c.fabricVLANs[vlanID]
	if !present {
		return fmt.Errorf("VLAN %d not found", vlanID)
	}

	delete(c.fabricVLANs, vlanID)
	return nil
}

// ListFabricNetworks lists the networks inside the given VLAN
func (c *CloudAPI) ListFabricNetworks(vlanID int16) ([]cloudapi.FabricNetwork, error) {
	vlan, err := c.getFabricWrapper(vlanID)
	if err != nil {
		return nil, err
	}

	out := []cloudapi.FabricNetwork{}
	for _, network := range vlan.Networks {
		out = append(out, *network)
	}

	return out, nil
}

// GetFabricNetwork gets a single network by VLAN and Network IDs
func (c *CloudAPI) GetFabricNetwork(vlanID int16, networkID string) (*cloudapi.FabricNetwork, error) {
	vlan, err := c.getFabricWrapper(vlanID)
	if err != nil {
		return nil, err
	}

	network, present := vlan.Networks[networkID]
	if !present {
		return nil, fmt.Errorf("Network %s not found", networkID)
	}

	return network, nil
}

// CreateFabricNetwork creates a new fabric network
func (c *CloudAPI) CreateFabricNetwork(vlanID int16, opts cloudapi.CreateFabricNetworkOpts) (*cloudapi.FabricNetwork, error) {
	id, err := localservices.NewUUID()
	if err != nil {
		return nil, err
	}

	vlan, err := c.getFabricWrapper(vlanID)
	if err != nil {
		return nil, err
	}

	vlan.Networks[id] = &cloudapi.FabricNetwork{
		Id:               id,
		Name:             opts.Name,
		Public:           false,
		Fabric:           true,
		Description:      opts.Description,
		Subnet:           opts.Subnet,
		ProvisionStartIp: opts.ProvisionStartIp,
		ProvisionEndIp:   opts.ProvisionEndIp,
		Gateway:          opts.Gateway,
		Routes:           opts.Routes,
		InternetNAT:      opts.InternetNAT,
		VLANId:           vlanID,
	}

	return vlan.Networks[id], nil
}

// DeleteFabricNetwork deletes an existing fabric network
func (c *CloudAPI) DeleteFabricNetwork(vlanID int16, networkID string) error {
	vlan, err := c.getFabricWrapper(vlanID)
	if err != nil {
		return err
	}

	_, present := vlan.Networks[networkID]
	if !present {
		return fmt.Errorf("Network %s not found", networkID)
	}

	delete(vlan.Networks, networkID)
	return nil
}
