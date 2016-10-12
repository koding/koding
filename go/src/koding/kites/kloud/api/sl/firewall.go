package sl

import "time"

type ACL struct {
	ID        int             `json:"id,omitempty"`
	Direction string          `json:"direction,omitempty"`
	MCIID     int             `json:"firewallContextInterfaceId,omitempty"`
	Rules     []*FirewallRule `json:"rules,omitempty"`
}

// MCI is a type for SoftLayer_Network_Firewall_Module_Context_Interface
type MCI struct {
	ID   int    `json:"id,omitempty"`
	Name string `json:"name,omitempty"`
	ACL  []*ACL `json:"firewallContextAccessControlLists,omitempty"`
}

type Firewall struct {
	ID             int             `json:"id,omitempty"`
	GuestNetworkID int             `json:"guestNetworkComponentId,omitempty"`
	NetworkID      int             `json:"networkComponentId,omitempty"`
	Status         string          `json:"status,omitempty"`
	IP             string          `json:"primaryIpAddress,omitempty"`
	Rules          []*FirewallRule `json:"rules,omitempty"`
}

type FirewallRequest struct {
	ID         int             `json:"id,omitempty"`
	CreateDate time.Time       `json:"createData,omitempty"`
	ACL        int             `json:"firewallContextAccessControlListId,omitempty"`
	NetworkID  int             `json:"networkComponentFirewallId,omitempty"`
	Rules      []*FirewallRule `json:"rules,omitempty"`
}

type FirewallRule struct {
	Action             string `json:"action,omitempty"`
	DestIP             string `json:"destinationIpAddress,omitempty"`
	DestCIDR           string `json:"destinationIpCidr,omitempty"`
	DestNetMask        string `json:"destinationIpSubnetMask,omitempty"`
	DestPortRangeStart int    `json:"destinationPortRangeStart,omitempty"`
	DestPortRangeEnd   int    `json:"destinationPortRangeEnd,omitempty"`
	Protocol           string `json:"protocol,omitempty"`
	SourceIP           string `json:"sourceIpAddress,omitempty"`
	SourceCIDR         string `json:"sourceIpCidr,omitempty"`
	SourceNetMask      string `json:"sourceIpSubnetMask,omitempty"`
	Version            int    `json:"version,omitempty"`
	FirewallRequestID  int    `json:"firewallUpdateRequestId,omitempty"`
}
