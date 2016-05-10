package cloudapi_test

import (
	"github.com/joyent/gosdc/cloudapi"
	gc "launchpad.net/gocheck"
)

func (s *LocalTests) addNIC(c *gc.C) (machine *cloudapi.Machine, nic *cloudapi.NIC, cleanup func()) {
	machine = s.createMachine(c)

	networks, err := s.testClient.ListNetworks()
	c.Assert(err, gc.IsNil)

	nic, err = s.testClient.AddNIC(machine.Id, networks[0].Id)
	c.Assert(err, gc.IsNil)

	return machine, nic, func() {
		s.testClient.RemoveNIC(machine.Id, nic.MAC)
		c.Assert(err, gc.IsNil)

		s.deleteMachine(c, machine.Id)
	}
}

func (s *LocalTests) TestAddNICs(c *gc.C) {
	_, _, cleanup := s.addNIC(c)
	defer cleanup()
}

func (s *LocalTests) TestListNICs(c *gc.C) {
	machine, nic, cleanup := s.addNIC(c)
	defer cleanup()

	nics, err := s.testClient.ListNICs(machine.Id)
	c.Assert(err, gc.IsNil)
	c.Assert(nics, gc.HasLen, 1)
	c.Assert(nics[0].MAC, gc.Equals, nic.MAC)
}

func (s *LocalTests) TestGetNIC(c *gc.C) {
	machine, nic, cleanup := s.addNIC(c)
	defer cleanup()

	nic2, err := s.testClient.GetNIC(machine.Id, nic.MAC)
	c.Assert(err, gc.IsNil)
	c.Assert(nic.MAC, gc.Equals, nic2.MAC)
}

func (s *LocalTests) TestRemoveNIC(c *gc.C) {
	machine, nic, _ := s.addNIC(c)
	defer s.deleteMachine(c, machine.Id)

	err := s.testClient.RemoveNIC(machine.Id, nic.MAC)
	c.Assert(err, gc.IsNil)

	_, err = s.testClient.GetNIC(machine.Id, nic.MAC)
	c.Assert(err, gc.Not(gc.IsNil))
}
