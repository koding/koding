package ec2

// RouteTable describes a route table which contains a set of rules, called routes
// that are used to determine where network traffic is directed.
//
// See http://goo.gl/bI9hkg for more details.
type RouteTable struct {
	Id              string                  `xml:"routeTableId"`
	VpcId           string                  `xml:"vpcId"`
	Routes          []Route                 `xml:"routeSet>item"`
	Associations    []RouteTableAssociation `xml:"associationSet>item"`
	PropagatingVgws []PropagatingVgw        `xml:"propagatingVgwSet>item"`
	Tags            []Tag                   `xml:"tagSet>item"`
}

// Route describes a route in a route table.
//
// See http://goo.gl/hE5Kxe for more details.
type Route struct {
	DestinationCidrBlock   string `xml:"destinationCidrBlock"`   // The CIDR block used for the destination match.
	GatewayId              string `xml:"gatewayId"`              // The ID of a gateway attached to your VPC.
	InstanceId             string `xml:"instanceId"`             // The ID of a NAT instance in your VPC.
	InstanceOwnerId        string `xml:"instanceOwnerId"`        // The AWS account ID of the owner of the instance.
	NetworkInterfaceId     string `xml:"networkInterfaceId"`     // The ID of the network interface.
	State                  string `xml:"state"`                  // The state of the route. Valid values: active | blackhole
	Origin                 string `xml:"origin"`                 // Describes how the route was created. Valid values: Valid values: CreateRouteTable | CreateRoute | EnableVgwRoutePropagation
	VpcPeeringConnectionId string `xml:"vpcPeeringConnectionId"` // The ID of the VPC peering connection.
}

// RouteTableAssociation describes an association between a route table and a subnet.
//
// See http://goo.gl/BZB8o8 for more details.
type RouteTableAssociation struct {
	Id           string `xml:"routeTableAssociationId"` // The ID of the association between a route table and a subnet.
	RouteTableId string `xml:"routeTableId"`            // The ID of the route table.
	SubnetId     string `xml:"subnetId"`                // The ID of the subnet.
	Main         bool   `xml:"main"`                    // Indicates whether this is the main route table.
}

// PropagatingVgw describes a virtual private gateway propagating route.
//
// See http://goo.gl/myGQtG for more details.
type PropagatingVgw struct {
	GatewayId string `xml:"gatewayID"`
}

// CreateRouteTableResp represents a response from a CreateRouteTable request
//
// See http://goo.gl/LD0TqP for more details.
type CreateRouteTableResp struct {
	RequestId  string     `xml:"requestId"`
	RouteTable RouteTable `xml:"routeTable"`
}

// CreateRouteTable creates a route table for the specified VPC.
// After you create a route table, you can add routes and associate the table with a subnet.
//
// See http://goo.gl/V9h6gE for more details..
func (ec2 *EC2) CreateRouteTable(vpcId string) (resp *CreateRouteTableResp, err error) {
	params := makeParams("CreateRouteTable")
	params["VpcId"] = vpcId
	resp = &CreateRouteTableResp{}
	err = ec2.query(params, resp)
	if err != nil {
		return nil, err
	}
	return
}

// DescribeRouteTablesResp represents a response from a DescribeRouteTables call
//
// See http://goo.gl/T3tVsg for more details.
type DescribeRouteTablesResp struct {
	RequestId   string       `xml:"requestId"`
	RouteTables []RouteTable `xml:"routeTableSet>item"`
}

// DescribeRouteTables describes one or more of your route tables
//
// See http://goo.gl/S0RVos for more details.
func (ec2 *EC2) DescribeRouteTables(routeTableIds []string, filter *Filter) (resp *DescribeRouteTablesResp, err error) {
	params := makeParams("DescribeRouteTables")
	addParamsList(params, "RouteTableId", routeTableIds)
	filter.addParams(params)
	resp = &DescribeRouteTablesResp{}
	err = ec2.query(params, resp)
	if err != nil {
		return nil, err
	}
	return
}

// AssociateRouteTableResp represents a response from an AssociateRouteTable call
//
// See http://goo.gl/T4KlYk for more details.
type AssociateRouteTableResp struct {
	RequestId     string `xml:"requestId"`
	AssociationId string `xml:"associationId"`
}

// AssociateRouteTable associates a subnet with a route table.
//
// The subnet and route table must be in the same VPC. This association causes
// traffic originating from the subnet to be routed according to the routes
// in the route table. The action returns an association ID, which you need in
// order to disassociate the route table from the subnet later.
// A route table can be associated with multiple subnets.
//
// See http://goo.gl/bfnONU for more details.
func (ec2 *EC2) AssociateRouteTable(routeTableId, subnetId string) (resp *AssociateRouteTableResp, err error) {
	params := makeParams("AssociateRouteTable")
	params["RouteTableId"] = routeTableId
	params["SubnetId"] = subnetId
	resp = &AssociateRouteTableResp{}
	err = ec2.query(params, resp)
	if err != nil {
		return nil, err
	}
	return
}

// DisassociateRouteTableResp represents the response from a DisassociateRouteTable request
//
// See http://goo.gl/1v4reT for more details.
type DisassociateRouteTableResp struct {
	RequestId string `xml:"requestId"`
	Return    bool   `xml:"return"` // True if the request succeeds
}

// DisassociateRouteTable disassociates a subnet from a route table.
//
// See http://goo.gl/A4NJum for more details.
func (ec2 *EC2) DisassociateRouteTable(associationId string) (resp *DisassociateRouteTableResp, err error) {
	params := makeParams("DisassociateRouteTable")
	params["AssociationId"] = associationId
	resp = &DisassociateRouteTableResp{}
	err = ec2.query(params, resp)
	if err != nil {
		return nil, err
	}
	return
}

// ReplaceRouteTableAssociationResp represents a response from a ReplaceRouteTableAssociation call
//
// See http://goo.gl/VhILGe for more details.
type ReplaceRouteTableAssociationResp struct {
	RequestId        string `xml:"requestId"`
	NewAssociationId string `xml:"newAssociationId"`
}

// ReplaceRouteTableAssociation changes the route table associated with a given subnet in a VPC.
//
// See http://goo.gl/kiit8j for more details.
func (ec2 *EC2) ReplaceRouteTableAssociation(associationId, routeTableId string) (resp *ReplaceRouteTableAssociationResp, err error) {
	params := makeParams("ReplaceRouteTableAssociation")
	params["AssociationId"] = associationId
	params["RouteTableId"] = routeTableId
	resp = &ReplaceRouteTableAssociationResp{}
	err = ec2.query(params, resp)
	if err != nil {
		return nil, err
	}
	return
}

// DeleteRouteTableResp represents a response from a DeleteRouteTable request
//
// See http://goo.gl/b8usig for more details.
type DeleteRouteTableResp struct {
	RequestId string `xml:"requestId"`
	Return    bool   `xml:"return"` // True if the request succeeds
}

// DeleteRouteTable deletes the specified route table.
// You must disassociate the route table from any subnets before you can delete it.
// You can't delete the main route table.
//
// See http://goo.gl/crHxT2 for more details.
func (ec2 *EC2) DeleteRouteTable(routeTableId string) (resp *DeleteRouteTableResp, err error) {
	params := makeParams("DeleteRouteTable")
	params["RouteTableId"] = routeTableId
	resp = &DeleteRouteTableResp{}
	err = ec2.query(params, resp)
	if err != nil {
		return nil, err
	}
	return
}
