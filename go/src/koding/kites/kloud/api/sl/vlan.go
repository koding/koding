package sl

import "time"

// SubnetDatacenter is a regular Datacenter, but lists less fields which
// are typically not used within subnet context.
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
var vlanMask = ObjectMask((*VLAN)(nil), "virtualGuests")

// vlanInstancesMask represents objectMask for Instance
var vlanInstancesMask = ObjectMask((*VLAN)(nil), "virtualGuests.networkVlans")

// VLAN represents a single Softlayer VLAN
type VLAN struct {
	ID            int             `json:"id,omitempty"`
	InternalID    int             `json:"vlanNumber,omitempty"`
	Name          string          `json:"name,omitempty"`
	ModifyDate    time.Time       `json:"modifyDate,omitempty"`
	RoutingID     int             `json:"networkVrfId,omitempty"`
	Subnet        Subnet          `json:"primarySubnet,omitempty"`
	InstanceCount int             `json:"virtualGuestCount,omitempty"`
	Instances     []*Instance     `json:"virtualGuests,omitempty"`
	Subnets       []Subnet        `json:"subnets,omitempty"`
	TagReferences []TagReference  `json:"tagReferences,omitempty"`
	Firewall      Firewall        `json:"networkVlanFirewall,omitempty"`
	MCI           []*MCI          `json:"firewallInterfaces,omitempty"`
	Firewalls     []*Firewall     `json:"firewallGuestNetworkComponents,omitempty"`
	FirewallRules []*FirewallRule `json:"firewallRules,omitempty"`

	Tags Tags `json:"-"`
}

func (v *VLAN) Err() error {
	if v == nil {
		return errNotFound
	}
	return nil
}

func (v *VLAN) Decode() {
	v.Tags = NewTagsFromRefs(v.TagReferences)
	Instances(v.Instances).Decode()
}

// VLANs is a convenience type for a list of VLANs that supports filtering.
type VLANs []*VLAN

func (v VLANs) Err() error {
	if len(v) == 0 {
		return errNotFound
	}
	return nil
}

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

// ByTags filters the vlans by tags.
func (v VLANs) ByTags(tags Tags) (res VLANs) {
	if len(tags) == 0 {
		return v
	}
	for _, vlan := range v {
		if vlan.Tags.Matches(tags) {
			res = append(res, vlan)
		}
	}
	return res
}

// ByDatacenter filters the vlans by datacenter name.
func (v VLANs) ByDatacenter(datacenter string) (res VLANs) {
	if datacenter == "" {
		return v
	}
	for _, vlan := range v {
		if vlan.Subnet.Datacenter.Name == datacenter {
			res = append(res, vlan)
			continue
		}
		if len(vlan.Subnets) != 0 && vlan.Subnets[0].Datacenter.Name == datacenter {
			res = append(res, vlan)
		}
	}
	return res
}

// Filter applies the given filter to VLANs.
func (v *VLANs) Filter(f *Filter) {
	*v = v.ByID(f.ID).ByDatacenter(f.Datacenter).ByTags(f.Tags)
}

// Decode implements the ResourceDecoder interface.
func (v VLANs) Decode() {
	for _, vlan := range v {
		vlan.Decode()
	}
}

// Sorts the VLANs by modify date.
func (v VLANs) Len() int           { return len(v) }
func (v VLANs) Less(j, k int) bool { return v[j].ModifyDate.After(v[k].ModifyDate) }
func (v VLANs) Swap(j, k int)      { v[j], v[k] = v[k], v[j] }
