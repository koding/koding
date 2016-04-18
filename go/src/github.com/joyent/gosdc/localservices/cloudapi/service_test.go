//
// gosdc - Go library to interact with the Joyent CloudAPI
//
// CloudAPI double testing service - internal direct API test
//
// Copyright (c) Joyent Inc.
//

package cloudapi_test

import (
	gc "launchpad.net/gocheck"
	"testing"

	"github.com/joyent/gosdc/cloudapi"
	lc "github.com/joyent/gosdc/localservices/cloudapi"
)

type CloudAPISuite struct {
	service *lc.CloudAPI
}

const (
	testServiceURL    = "https://go-test.api.joyentcloud.com"
	testUserAccount   = "gouser"
	testKeyName       = "test-key"
	testKey           = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDLF4s7GLYfPYVr3zqZcNCZcM2qFDXXxE5pCGuGowySGKTnxrqrPY4HO+9CQ+5X55o4rJOfNJ9ZRa+2Qmlr4F/qACcT/ZJbXPs+LcbOVtgUaynn6ooh0C4V/MdKPZmW8FSTy98GstVJZXJO2gJwlKGHQwoWuZ5H/IeN6gCaXi65NPg4eu3Ls9a6BtvOf1Vtb1wwl7QqoZqziT5omA9bDeoBXdoYOoowDS3LUprFRvc1lW7fY9eLKNvoQ4oOJMMn5cPh2CICj5cb2eRH1pHJA/9mxxW4+bB7QdL3N7hDbpV4Qz5MxjxYN3DWldvyP1zCe/Tgyduiz4X3gDBhy735Bpat gouser@localhost"
	testPackage       = "Small"
	testImage         = "11223344-0a0a-ff99-11bb-0a1b2c3d4e5f"
	testMachineName   = "test-machine"
	testFwRule        = "FROM subnet 10.35.76.0/24 TO subnet 10.35.101.0/24 ALLOW tcp (PORT 80 AND PORT 443)"
	testUpdatedFwRule = "FROM subnet 10.35.76.0/24 TO subnet 10.35.101.0/24 ALLOW tcp (port 80 AND port 443 AND port 8080)"
	testNetworkID     = "123abc4d-0011-aabb-2233-ccdd4455"
)

var _ = gc.Suite(&CloudAPISuite{})

func Test(t *testing.T) {
	gc.TestingT(t)
}

func (s *CloudAPISuite) SetUpSuite(c *gc.C) {
	s.service = lc.New(testServiceURL, testUserAccount)
}

// Helpers
func (s *CloudAPISuite) createKey(c *gc.C, keyName, key string) *cloudapi.Key {
	k, err := s.service.CreateKey(keyName, key)
	c.Assert(err, gc.IsNil)

	return k
}

func (s *CloudAPISuite) deleteKey(c *gc.C, keyName string) {
	err := s.service.DeleteKey(keyName)
	c.Assert(err, gc.IsNil)
}

func (s *CloudAPISuite) createMachine(c *gc.C, name, pkg, image string, metadata, tags map[string]string) *cloudapi.Machine {
	m, err := s.service.CreateMachine(name, pkg, image, []string{testNetworkID}, metadata, tags)
	c.Assert(err, gc.IsNil)

	return m
}

func (s *CloudAPISuite) deleteMachine(c *gc.C, machineID string) {
	err := s.service.StopMachine(machineID)
	c.Assert(err, gc.IsNil)
	err = s.service.DeleteMachine(machineID)
	c.Assert(err, gc.IsNil)
}

// Helper method to create a test firewall rule
func (s *CloudAPISuite) createFirewallRule(c *gc.C) *cloudapi.FirewallRule {
	fwRule, err := s.service.CreateFirewallRule(testFwRule, false)
	c.Assert(err, gc.IsNil)
	c.Assert(fwRule, gc.NotNil)
	c.Assert(fwRule.Rule, gc.Equals, testFwRule)
	c.Assert(fwRule.Enabled, gc.Equals, false)

	return fwRule
}

// Helper method to a test firewall rule
func (s *CloudAPISuite) deleteFwRule(c *gc.C, fwRuleID string) {
	err := s.service.DeleteFirewallRule(fwRuleID)
	c.Assert(err, gc.IsNil)
}

// Tests for Keys API
func (s *CloudAPISuite) TestListKeys(c *gc.C) {
	k := s.createKey(c, testKeyName, testKey)
	defer s.deleteKey(c, testKeyName)

	keys, err := s.service.ListKeys()
	c.Assert(err, gc.IsNil)
	for _, key := range keys {
		if c.Check(&key, gc.DeepEquals, k) {
			c.SucceedNow()
		}
	}
	c.Fatalf("Obtained keys [%s] do not contain test key [%s]", keys, k)
}

func (s *CloudAPISuite) TestGetKey(c *gc.C) {
	k := s.createKey(c, testKeyName, testKey)
	defer s.deleteKey(c, testKeyName)

	key, err := s.service.GetKey(testKeyName)
	c.Assert(err, gc.IsNil)
	c.Assert(key, gc.DeepEquals, k)
}

func (s *CloudAPISuite) TestCreateKey(c *gc.C) {
	k := s.createKey(c, testKeyName, testKey)
	defer s.deleteKey(c, testKeyName)

	c.Assert(k.Name, gc.Equals, testKeyName)
	c.Assert(k.Key, gc.Equals, testKey)
}

func (s *CloudAPISuite) TestDeleteKey(c *gc.C) {
	s.createKey(c, testKeyName, testKey)
	s.deleteKey(c, testKeyName)
}

// Tests for Package API
func (s *CloudAPISuite) TestListPackages(c *gc.C) {
	pkgs, err := s.service.ListPackages(nil)
	c.Assert(err, gc.IsNil)
	c.Assert(len(pkgs), gc.Equals, 4)
}

func (s *CloudAPISuite) TestListPackagesWithFilter(c *gc.C) {
	pkgs, err := s.service.ListPackages(map[string]string{"memory": "1024"})
	c.Assert(err, gc.IsNil)
	c.Assert(len(pkgs), gc.Equals, 1)
}

func (s *CloudAPISuite) TestGetPackage(c *gc.C) {
	pkg, err := s.service.GetPackage(testPackage)
	c.Assert(err, gc.IsNil)
	c.Assert(pkg.Name, gc.Equals, "Small")
	c.Assert(pkg.Memory, gc.Equals, 1024)
	c.Assert(pkg.Disk, gc.Equals, 16384)
	c.Assert(pkg.Swap, gc.Equals, 2048)
	c.Assert(pkg.VCPUs, gc.Equals, 1)
	c.Assert(pkg.Default, gc.Equals, true)
	c.Assert(pkg.Id, gc.Equals, "11223344-1212-abab-3434-aabbccddeeff")
	c.Assert(pkg.Version, gc.Equals, "1.0.2")
}

// Tests for Images API
func (s *CloudAPISuite) TestListImages(c *gc.C) {
	images, err := s.service.ListImages(nil)
	c.Assert(err, gc.IsNil)
	c.Assert(len(images), gc.Equals, 6)
}

func (s *CloudAPISuite) TestListImagesWithFilter(c *gc.C) {
	images, err := s.service.ListImages(map[string]string{"os": "linux"})
	c.Assert(err, gc.IsNil)
	c.Assert(len(images), gc.Equals, 4)
}

func (s *CloudAPISuite) TestGetImage(c *gc.C) {
	image, err := s.service.GetImage(testImage)
	c.Assert(err, gc.IsNil)
	c.Assert(image.Id, gc.Equals, "11223344-0a0a-ff99-11bb-0a1b2c3d4e5f")
	c.Assert(image.Name, gc.Equals, "ubuntu12.04")
	c.Assert(image.OS, gc.Equals, "linux")
	c.Assert(image.Version, gc.Equals, "2.3.1")
	c.Assert(image.Type, gc.Equals, "virtualmachine")
	c.Assert(image.Description, gc.Equals, "Test Ubuntu 12.04 image (64 bit)")
	c.Assert(image.PublishedAt, gc.Equals, "2014-01-20T16:12:31Z")
	c.Assert(image.Public, gc.Equals, true)
	c.Assert(image.State, gc.Equals, "active")
}

// Test for Machine API
func (s *CloudAPISuite) TestListMachines(c *gc.C) {
	m := s.createMachine(c, testMachineName, testPackage, testImage, nil, nil)
	defer s.deleteMachine(c, m.Id)

	machines, err := s.service.ListMachines(nil)
	c.Assert(err, gc.IsNil)
	for _, machine := range machines {
		if machine.Id == m.Id {
			c.SucceedNow()
		}
	}
	c.Fatalf("Obtained machine [%v] do not contain test machine [%v]", machines, m)
}

func (s *CloudAPISuite) TestCountMachines(c *gc.C) {
	m := s.createMachine(c, testMachineName, testPackage, testImage, nil, nil)
	defer s.deleteMachine(c, m.Id)

	count, err := s.service.CountMachines()
	c.Assert(err, gc.IsNil)
	c.Assert(count, gc.Equals, 1)
}

func (s *CloudAPISuite) TestGetMachine(c *gc.C) {
	m := s.createMachine(c, testMachineName, testPackage, testImage, nil, nil)
	defer s.deleteMachine(c, m.Id)

	machine, err := s.service.GetMachine(m.Id)
	c.Assert(err, gc.IsNil)
	c.Assert(machine.Name, gc.Equals, testMachineName)
	c.Assert(machine.Package, gc.Equals, testPackage)
	c.Assert(machine.Image, gc.Equals, testImage)
}

func (s *CloudAPISuite) TestCreateMachine(c *gc.C) {
	m := s.createMachine(c, testMachineName, testPackage, testImage, nil, nil)
	defer s.deleteMachine(c, m.Id)

	c.Assert(m.Name, gc.Equals, testMachineName)
	c.Assert(m.Package, gc.Equals, testPackage)
	c.Assert(m.Image, gc.Equals, testImage)
	c.Assert(m.Type, gc.Equals, "virtualmachine")
	c.Assert(len(m.IPs), gc.Equals, 2)
	c.Assert(m.State, gc.Equals, "running")
}

func (s *CloudAPISuite) TestStartMachine(c *gc.C) {
	m := s.createMachine(c, testMachineName, testPackage, testImage, nil, nil)
	defer s.deleteMachine(c, m.Id)

	err := s.service.StartMachine(m.Id)
	c.Assert(err, gc.IsNil)

	machine, err := s.service.GetMachine(m.Id)
	c.Assert(err, gc.IsNil)
	c.Assert(machine.State, gc.Equals, "running")
}

func (s *CloudAPISuite) TestStopMachine(c *gc.C) {
	m := s.createMachine(c, testMachineName, testPackage, testImage, nil, nil)
	defer s.deleteMachine(c, m.Id)

	err := s.service.StopMachine(m.Id)
	c.Assert(err, gc.IsNil)

	machine, err := s.service.GetMachine(m.Id)
	c.Assert(err, gc.IsNil)
	c.Assert(machine.State, gc.Equals, "stopped")
}

func (s *CloudAPISuite) TestRebootMachine(c *gc.C) {
	m := s.createMachine(c, testMachineName, testPackage, testImage, nil, nil)
	defer s.deleteMachine(c, m.Id)

	err := s.service.RebootMachine(m.Id)
	c.Assert(err, gc.IsNil)

	machine, err := s.service.GetMachine(m.Id)
	c.Assert(err, gc.IsNil)
	c.Assert(machine.State, gc.Equals, "running")
}

func (s *CloudAPISuite) TestResizeMachine(c *gc.C) {
	m := s.createMachine(c, testMachineName, testPackage, testImage, nil, nil)
	defer s.deleteMachine(c, m.Id)

	err := s.service.ResizeMachine(m.Id, "Medium")
	c.Assert(err, gc.IsNil)

	machine, err := s.service.GetMachine(m.Id)
	c.Assert(err, gc.IsNil)
	c.Assert(machine.Package, gc.Equals, "Medium")
	c.Assert(machine.Memory, gc.Equals, 2048)
	c.Assert(machine.Disk, gc.Equals, 32768)
}

func (s *CloudAPISuite) TestRenameMachine(c *gc.C) {
	m := s.createMachine(c, testMachineName, testPackage, testImage, nil, nil)
	defer s.deleteMachine(c, m.Id)

	err := s.service.RenameMachine(m.Id, "new-test-name")
	c.Assert(err, gc.IsNil)

	machine, err := s.service.GetMachine(m.Id)
	c.Assert(err, gc.IsNil)
	c.Assert(machine.Name, gc.Equals, "new-test-name")
}

func (s *CloudAPISuite) TestListMachinesFirewallRules(c *gc.C) {
	m := s.createMachine(c, testMachineName, testPackage, testImage, nil, nil)
	defer s.deleteMachine(c, m.Id)

	fwRules, err := s.service.ListMachineFirewallRules(m.Id)
	c.Assert(err, gc.IsNil)
	c.Assert(fwRules, gc.NotNil)
}

func (s *CloudAPISuite) TestEnableFirewallMachine(c *gc.C) {
	m := s.createMachine(c, testMachineName, testPackage, testImage, nil, nil)
	defer s.deleteMachine(c, m.Id)

	err := s.service.EnableFirewallMachine(m.Id)
	c.Assert(err, gc.IsNil)
}

func (s *CloudAPISuite) TestDisableFirewallMachine(c *gc.C) {
	m := s.createMachine(c, testMachineName, testPackage, testImage, nil, nil)
	defer s.deleteMachine(c, m.Id)

	err := s.service.DisableFirewallMachine(m.Id)
	c.Assert(err, gc.IsNil)
}

func (s *CloudAPISuite) TestDeleteMachine(c *gc.C) {
	m := s.createMachine(c, testMachineName, testPackage, testImage, nil, nil)
	s.deleteMachine(c, m.Id)
}

// Tests for FirewallRules API
func (s *CloudAPISuite) TestCreateFirewallRule(c *gc.C) {
	testFwRule := s.createFirewallRule(c)

	// cleanup
	s.deleteFwRule(c, testFwRule.Id)
}

func (s *CloudAPISuite) TestListFirewallRules(c *gc.C) {
	testFwRule := s.createFirewallRule(c)

	rules, err := s.service.ListFirewallRules()
	c.Assert(err, gc.IsNil)
	c.Assert(rules, gc.NotNil)

	// cleanup
	s.deleteFwRule(c, testFwRule.Id)
}

func (s *CloudAPISuite) TestGetFirewallRule(c *gc.C) {
	testFwRule := s.createFirewallRule(c)

	fwRule, err := s.service.GetFirewallRule(testFwRule.Id)
	c.Assert(err, gc.IsNil)
	c.Assert(fwRule, gc.NotNil)
	c.Assert((*fwRule), gc.DeepEquals, (*testFwRule))

	// cleanup
	s.deleteFwRule(c, testFwRule.Id)
}

func (s *CloudAPISuite) TestUpdateFirewallRule(c *gc.C) {
	testFwRule := s.createFirewallRule(c)

	fwRule, err := s.service.UpdateFirewallRule(testFwRule.Id, testUpdatedFwRule, true)
	c.Assert(err, gc.IsNil)
	c.Assert(fwRule, gc.NotNil)
	c.Assert(fwRule.Rule, gc.Equals, testUpdatedFwRule)

	// cleanup
	s.deleteFwRule(c, testFwRule.Id)
}

func (s *CloudAPISuite) TestEnableFirewallRule(c *gc.C) {
	testFwRule := s.createFirewallRule(c)

	fwRule, err := s.service.EnableFirewallRule((*testFwRule).Id)
	c.Assert(err, gc.IsNil)
	c.Assert(fwRule, gc.NotNil)

	// cleanup
	s.deleteFwRule(c, testFwRule.Id)
}

func (s *CloudAPISuite) TestListFirewallRuleMachines(c *gc.C) {
	testFwRule := s.createFirewallRule(c)

	machines, err := s.service.ListFirewallRuleMachines((*testFwRule).Id)
	c.Assert(err, gc.IsNil)
	c.Assert(machines, gc.NotNil)

	// cleanup
	s.deleteFwRule(c, testFwRule.Id)
}

func (s *CloudAPISuite) TestDisableFirewallRule(c *gc.C) {
	testFwRule := s.createFirewallRule(c)

	fwRule, err := s.service.DisableFirewallRule((*testFwRule).Id)
	c.Assert(err, gc.IsNil)
	c.Assert(fwRule, gc.NotNil)

	// cleanup
	s.deleteFwRule(c, testFwRule.Id)
}

func (s *CloudAPISuite) TestDeleteFirewallRule(c *gc.C) {
	testFwRule := s.createFirewallRule(c)

	s.deleteFwRule(c, testFwRule.Id)
}

// tests for Networks API
func (s *CloudAPISuite) TestListNetworks(c *gc.C) {
	nets, err := s.service.ListNetworks()
	c.Assert(err, gc.IsNil)
	c.Assert(nets, gc.NotNil)
}

func (s *CloudAPISuite) TestGetNetwork(c *gc.C) {
	net, err := s.service.GetNetwork(testNetworkID)
	c.Assert(err, gc.IsNil)
	c.Assert(net, gc.NotNil)
	c.Assert(net, gc.DeepEquals, &cloudapi.Network{
		Id:          testNetworkID,
		Name:        "Test-Joyent-Public",
		Public:      true,
		Description: "",
	})
}
