package cloudapi_test

import (
	"github.com/joyent/gosdc/cloudapi"
	gc "launchpad.net/gocheck"
)

func (s *LocalTests) createFabricVLAN(c *gc.C) (vlan *cloudapi.FabricVLAN, cleanup func()) {
	vlan, err := s.testClient.CreateFabricVLAN(cloudapi.FabricVLAN{
		Name:        "test VLAN",
		Description: "VLAN for test purposes",
	})
	c.Assert(err, gc.IsNil)

	return vlan, func() {
		err := s.testClient.DeleteFabricVLAN(vlan.Id)
		c.Assert(err, gc.IsNil)
	}
}

func (s *LocalTests) createFabricNetwork(c *gc.C) (vlan *cloudapi.FabricVLAN, network *cloudapi.FabricNetwork, cleanup func()) {
	vlan, vlanCleanup := s.createFabricVLAN(c)
	network, err := s.testClient.CreateFabricNetwork(vlan.Id, cloudapi.CreateFabricNetworkOpts{
		Name:             "test network",
		Subnet:           "10.0.0.0/16",
		ProvisionStartIp: "10.0.0.0",
		ProvisionEndIp:   "10.0.255.255",
		InternetNAT:      true,
	})
	c.Assert(err, gc.IsNil)

	return vlan, network, func() {
		err := s.testClient.DeleteFabricNetwork(vlan.Id, network.Id)
		c.Assert(err, gc.IsNil)

		vlanCleanup()
	}
}

func (s *LocalTests) TestCreateFabricVLAN(c *gc.C) {
	vlan, cleanup := s.createFabricVLAN(c)
	defer cleanup()

	c.Assert(vlan.Id, gc.Not(gc.Equals), 0)
}

func (s *LocalTests) TestListFabricVLANs(c *gc.C) {
	vlan, cleanup := s.createFabricVLAN(c)
	defer cleanup()

	vlans, err := s.testClient.ListFabricVLANs()
	c.Assert(err, gc.IsNil)
	c.Assert(vlans, gc.HasLen, 1)
	c.Assert(vlans[0].Id, gc.Equals, vlan.Id)
}

func (s *LocalTests) TestGetFabricVLAN(c *gc.C) {
	vlan, cleanup := s.createFabricVLAN(c)
	defer cleanup()

	vlan2, err := s.testClient.GetFabricVLAN(vlan.Id)
	c.Assert(err, gc.IsNil)

	c.Assert(vlan.Id, gc.Equals, vlan2.Id)
	c.Assert(vlan.Name, gc.Equals, vlan2.Name)
	c.Assert(vlan.Description, gc.Equals, vlan2.Description)
}

func (s *LocalTests) TestUpdateFabricVLAN(c *gc.C) {
	vlan, cleanup := s.createFabricVLAN(c)
	defer cleanup()

	vlan.Description = "test change"
	updated, err := s.testClient.UpdateFabricVLAN(*vlan)
	c.Assert(err, gc.IsNil)
	c.Assert(updated.Description, gc.Equals, vlan.Description)
}

func (s *LocalTests) TestDeleteFabricVLAN(c *gc.C) {
	vlan, _ := s.createFabricVLAN(c)

	err := s.testClient.DeleteFabricVLAN(vlan.Id)
	c.Assert(err, gc.IsNil)

	_, err = s.testClient.GetFabricVLAN(vlan.Id)
	c.Assert(err, gc.Not(gc.IsNil))
}

func (s *LocalTests) TestCreateFabricNetwork(c *gc.C) {
	vlan, network, cleanup := s.createFabricNetwork(c)
	defer cleanup()

	c.Assert(network.Id, gc.Not(gc.Equals), "")
	c.Assert(vlan.Id, gc.Equals, network.VLANId)
}

func (s *LocalTests) TestListFabricNetworks(c *gc.C) {
	vlan, network, cleanup := s.createFabricNetwork(c)
	defer cleanup()

	networks, err := s.testClient.ListFabricNetworks(vlan.Id)
	c.Assert(err, gc.IsNil)
	c.Assert(networks, gc.HasLen, 1)
	c.Assert(networks[0].Id, gc.Equals, network.Id)
}

func (s *LocalTests) TestGetFabricNetwork(c *gc.C) {
	vlan, network, cleanup := s.createFabricNetwork(c)
	defer cleanup()

	network2, err := s.testClient.GetFabricNetwork(vlan.Id, network.Id)
	c.Assert(err, gc.IsNil)
	c.Assert(network2.Id, gc.Equals, network.Id)
}

func (s *LocalTests) TestDeleteFabricNetwork(c *gc.C) {
	vlan, cleanup := s.createFabricVLAN(c)
	defer cleanup()

	network, err := s.testClient.CreateFabricNetwork(vlan.Id, cloudapi.CreateFabricNetworkOpts{
		Name:             "test network",
		Subnet:           "10.0.0.0/16",
		ProvisionStartIp: "10.0.0.0",
		ProvisionEndIp:   "10.0.255.255",
		InternetNAT:      true,
	})
	c.Assert(err, gc.IsNil)

	err = s.testClient.DeleteFabricNetwork(vlan.Id, network.Id)
	c.Assert(err, gc.IsNil)

	_, err = s.testClient.GetFabricNetwork(vlan.Id, network.Id)
	c.Assert(err, gc.Not(gc.IsNil))
}
