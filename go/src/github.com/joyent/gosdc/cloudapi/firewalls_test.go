package cloudapi_test

import (
	gc "launchpad.net/gocheck"

	"github.com/joyent/gosdc/cloudapi"
)

func (s *LocalTests) TestCreateFirewallRule(c *gc.C) {
	testFwRule := s.createFirewallRule(c)

	// cleanup
	s.deleteFwRule(c, testFwRule.Id)
}

func (s *LocalTests) TestListFirewallRules(c *gc.C) {
	testFwRule := s.createFirewallRule(c)
	defer s.deleteFwRule(c, testFwRule.Id)

	rules, err := s.testClient.ListFirewallRules()
	c.Assert(err, gc.IsNil)
	c.Assert(rules, gc.NotNil)
}

func (s *LocalTests) TestGetFirewallRule(c *gc.C) {
	testFwRule := s.createFirewallRule(c)
	defer s.deleteFwRule(c, testFwRule.Id)

	fwRule, err := s.testClient.GetFirewallRule(testFwRule.Id)
	c.Assert(err, gc.IsNil)
	c.Assert(fwRule, gc.NotNil)
	c.Assert((*fwRule), gc.DeepEquals, (*testFwRule))
}

func (s *LocalTests) TestUpdateFirewallRule(c *gc.C) {
	testFwRule := s.createFirewallRule(c)
	defer s.deleteFwRule(c, testFwRule.Id)

	fwRule, err := s.testClient.UpdateFirewallRule(testFwRule.Id, cloudapi.CreateFwRuleOpts{Rule: testUpdatedFwRule})
	c.Assert(err, gc.IsNil)
	c.Assert(fwRule, gc.NotNil)
	c.Assert(fwRule.Rule, gc.Equals, testUpdatedFwRule)
}

func (s *LocalTests) TestEnableFirewallRule(c *gc.C) {
	testFwRule := s.createFirewallRule(c)
	defer s.deleteFwRule(c, testFwRule.Id)

	fwRule, err := s.testClient.EnableFirewallRule((*testFwRule).Id)
	c.Assert(err, gc.IsNil)
	c.Assert(fwRule, gc.NotNil)
}

func (s *LocalTests) TestDisableFirewallRule(c *gc.C) {
	testFwRule := s.createFirewallRule(c)
	defer s.deleteFwRule(c, testFwRule.Id)

	fwRule, err := s.testClient.DisableFirewallRule((*testFwRule).Id)
	c.Assert(err, gc.IsNil)
	c.Assert(fwRule, gc.NotNil)
}

func (s *LocalTests) TestDeleteFirewallRule(c *gc.C) {
	testFwRule := s.createFirewallRule(c)

	s.deleteFwRule(c, testFwRule.Id)
}
