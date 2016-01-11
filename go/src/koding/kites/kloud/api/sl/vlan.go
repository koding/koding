package sl

import "time"

// SubnetDatacenter is a regular Datacenter, but lists less fields which
// are typicaly not used within subnet context.
type SubnetDatacenter struct {
	ID       int    `json:"id,omitempty"`
	Name     string `json:"name,omitempty"`
	LongName string `json:"longName,omitempty"`
}

// Subnet represents a single Softlayer subnet.
type Subnet struct {
	ID         int              `json:"id,omitempty"`
	NetworkID  string           `json:"networkIdentifier,omitempty"`
	Type       string           `json:"subnetType,omitempty"`
	Netmaks    string           `json:"netmask,omitempty"`
	Broadcast  string           `json:"broadcastAddress,omitempty"`
	Gateway    string           `json:"gateway,omitempty"`
	CIDR       int              `json:"cidr,omitempty"`
	Total      int              `json:"totalIpAddresses,omitempty"`
	Available  int              `json:"usableIpAddressCount,omitempty"`
	POD        string           `json:"pod,omitempty"`
	Datacenter SubnetDatacenter `json:"datacenter,omitempty"`
}

// vlanMask represents objectMask for the VLAN struct.
var vlanMask = ObjectMask((*VLAN)(nil))

// VLAN represents a single Softlayer VLAN
type VLAN struct {
	ID         int       `json:"id,omitempty"`
	InternalID int       `json:"vlanNumber,omitempty"`
	Name       string    `json:"name,omitempty"`
	ModifyDate time.Time `json:"modifyDate,omitempty"`
	RoutingID  int       `json:"networkVrfId,omitempty"`
	Subnet     Subnet    `json:"primarySubnet,omitempty"`
	Subnets    []Subnet  `json:"subnets,omitempty"`
}

// VLANs is a conveniance type for a list of VLANs that supports filtering.
type VLANs []*VLAN

// ByID filters the VLANs by ID.
func (v VLANs) ByID(id int) VLANs {
	if id == 0 {
		return v
	}
	for _, vlan := range v {
		if vlan.ID == id {
			return VLANs{vlan}
		}
	}
	return nil
}

// Filter applies the given filter to VLANs.
func (v *VLANs) Filter(f *Filter) {
	*v = v.ByID(f.ID)
}

// Sorts the VLANs by modify date.
func (v VLANs) Len() int           { return len(v) }
func (v VLANs) Less(j, k int) bool { return v[j].ModifyDate.After(v[k].ModifyDate) }
func (v VLANs) Swap(j, k int)      { v[j], v[k] = v[k], v[j] }
