package cloudapi_test

import (
	gc "launchpad.net/gocheck"
)

func (s *LocalTests) TestListMachinesFirewallRules(c *gc.C) {
	testMachine := s.createMachine(c)
	defer s.deleteMachine(c, testMachine.Id)

	fwRules, err := s.testClient.ListMachineFirewallRules(testMachine.Id)
	c.Assert(err, gc.IsNil)
	c.Assert(fwRules, gc.NotNil)
}

func (s *LocalTests) TestEnableFirewallMachine(c *gc.C) {
	testMachine := s.createMachine(c)
	defer s.deleteMachine(c, testMachine.Id)

	err := s.testClient.EnableFirewallMachine(testMachine.Id)
	c.Assert(err, gc.IsNil)
}

func (s *LocalTests) TestDisableFirewallMachine(c *gc.C) {
	testMachine := s.createMachine(c)
	defer s.deleteMachine(c, testMachine.Id)

	err := s.testClient.DisableFirewallMachine(testMachine.Id)
	c.Assert(err, gc.IsNil)
}
