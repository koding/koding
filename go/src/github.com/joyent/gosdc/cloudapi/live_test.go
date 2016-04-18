//
// gosdc - Go library to interact with the Joyent CloudAPI
//
//
// Copyright (c) 2013 Joyent Inc.
//
// Written by Daniele Stroppa <daniele.stroppa@joyent.com>
//

package cloudapi_test

import (
	"log"
	"os"
	"strings"
	"time"

	gc "launchpad.net/gocheck"

	"github.com/joyent/gocommon/client"
	"github.com/joyent/gosdc/cloudapi"
	"github.com/joyent/gosign/auth"
)

func registerJoyentCloudTests(creds *auth.Credentials) {
	gc.Suite(&LiveTests{creds: creds})
}

type LiveTests struct {
	creds      *auth.Credentials
	testClient *cloudapi.Client
}

func (s *LiveTests) SetUpTest(c *gc.C) {
	client := client.NewClient(s.creds.SdcEndpoint.URL, cloudapi.DefaultAPIVersion, s.creds, log.New(os.Stderr, "", log.LstdFlags))
	c.Assert(client, gc.NotNil)
	s.testClient = cloudapi.New(client)
	c.Assert(s.testClient, gc.NotNil)
}

// Helper method to create a test key in the user account
func (s *LiveTests) createKey(c *gc.C) {
	key, err := s.testClient.CreateKey(cloudapi.CreateKeyOpts{Name: "fake-key", Key: testKey})
	c.Assert(err, gc.IsNil)
	c.Assert(key, gc.NotNil)
	c.Assert(key, gc.DeepEquals, &cloudapi.Key{Name: "fake-key", Fingerprint: testKeyFingerprint, Key: testKey})
}

// Helper method to create a test virtual machine in the user account
func (s *LiveTests) createMachine(c *gc.C) *cloudapi.Machine {
	machine, err := s.testClient.CreateMachine(cloudapi.CreateMachineOpts{Package: packageName, Image: imageID})
	c.Assert(err, gc.IsNil)
	c.Assert(machine, gc.NotNil)

	// wait for machine to be provisioned
	for !s.pollMachineState(c, machine.Id, "running") {
		time.Sleep(1 * time.Second)
	}

	return machine
}

// Helper method to create a test virtual machine in the user account with the specified tags
func (s *LiveTests) createMachineWithTags(c *gc.C, tags map[string]string) *cloudapi.Machine {
	machine, err := s.testClient.CreateMachine(cloudapi.CreateMachineOpts{Package: packageName, Image: imageID, Tags: tags})
	c.Assert(err, gc.IsNil)
	c.Assert(machine, gc.NotNil)

	// wait for machine to be provisioned
	for !s.pollMachineState(c, machine.Id, "running") {
		time.Sleep(1 * time.Second)
	}

	return machine
}

// Helper method to test the state of a given VM
func (s *LiveTests) pollMachineState(c *gc.C, machineId, state string) bool {
	machineConfig, err := s.testClient.GetMachine(machineId)
	c.Assert(err, gc.IsNil)
	return strings.EqualFold(machineConfig.State, state)
}

// Helper method to delete a test virtual machine once the test has executed
func (s *LiveTests) deleteMachine(c *gc.C, machineId string) {
	err := s.testClient.StopMachine(machineId)
	c.Assert(err, gc.IsNil)

	// wait for machine to be stopped
	for !s.pollMachineState(c, machineId, "stopped") {
		time.Sleep(1 * time.Second)
	}

	err = s.testClient.DeleteMachine(machineId)
	c.Assert(err, gc.IsNil)
}

// Helper method to list virtual machine according to the specified filter
func (s *LiveTests) listMachines(c *gc.C, filter *cloudapi.Filter) {
	var contains bool
	testMachine := s.createMachine(c)
	defer s.deleteMachine(c, testMachine.Id)

	machines, err := s.testClient.ListMachines(filter)
	c.Assert(err, gc.IsNil)
	c.Assert(machines, gc.NotNil)
	for _, m := range machines {
		if m.Id == testMachine.Id {
			contains = true
			break
		}
	}

	// result
	if !contains {
		c.Fatalf("Obtained machines [%s] do not contain test machine [%s]", machines, *testMachine)
	}
}

// Helper method to create a snapshot of a test virtual machine
func (s *LiveTests) createMachineSnapshot(c *gc.C, machineId string) string {
	// generates a unique snapshot name using the current timestamp
	t := time.Now()
	snapshotName := "test-machine-snapshot-" + t.Format("20060102_150405")
	snapshot, err := s.testClient.CreateMachineSnapshot(machineId, cloudapi.SnapshotOpts{Name: snapshotName})
	c.Assert(err, gc.IsNil)
	c.Assert(snapshot, gc.NotNil)
	c.Assert(snapshot, gc.DeepEquals, &cloudapi.Snapshot{Name: snapshotName, State: "queued"})

	return snapshotName
}

// Helper method to create a test firewall rule
func (s *LiveTests) createFirewallRule(c *gc.C) *cloudapi.FirewallRule {
	fwRule, err := s.testClient.CreateFirewallRule(cloudapi.CreateFwRuleOpts{Enabled: false, Rule: testFwRule})
	c.Assert(err, gc.IsNil)
	c.Assert(fwRule, gc.NotNil)
	c.Assert(fwRule.Rule, gc.Equals, testFwRule)
	c.Assert(fwRule.Enabled, gc.Equals, false)
	time.Sleep(10 * time.Second)

	return fwRule
}

// Helper method to a test firewall rule
func (s *LiveTests) deleteFwRule(c *gc.C, fwRuleId string) {
	err := s.testClient.DeleteFirewallRule(fwRuleId)
	c.Assert(err, gc.IsNil)
}

// Keys API
func (s *LiveTests) TestCreateKey(c *gc.C) {
	s.createKey(c)
}

func (s *LiveTests) TestListKeys(c *gc.C) {
	s.createKey(c)

	keys, err := s.testClient.ListKeys()
	c.Assert(err, gc.IsNil)
	c.Assert(keys, gc.NotNil)
	fakeKey := cloudapi.Key{Name: "fake-key", Fingerprint: testKeyFingerprint, Key: testKey}
	for _, k := range keys {
		if c.Check(k, gc.DeepEquals, fakeKey) {
			c.SucceedNow()
		}
	}
	c.Fatalf("Obtained keys [%s] do not contain test key [%s]", keys, fakeKey)
}

func (s *LiveTests) TestGetKeyByName(c *gc.C) {
	s.createKey(c)

	key, err := s.testClient.GetKey("fake-key")
	c.Assert(err, gc.IsNil)
	c.Assert(key, gc.NotNil)
	c.Assert(key, gc.DeepEquals, &cloudapi.Key{Name: "fake-key", Fingerprint: testKeyFingerprint, Key: testKey})
}

func (s *LiveTests) TestGetKeyByFingerprint(c *gc.C) {
	s.createKey(c)

	key, err := s.testClient.GetKey(testKeyFingerprint)
	c.Assert(err, gc.IsNil)
	c.Assert(key, gc.NotNil)
	c.Assert(key, gc.DeepEquals, &cloudapi.Key{Name: "fake-key", Fingerprint: testKeyFingerprint, Key: testKey})
}

func (s *LiveTests) TestDeleteKey(c *gc.C) {
	s.createKey(c)

	err := s.testClient.DeleteKey("fake-key")
	c.Assert(err, gc.IsNil)
}

// Packages API
func (s *LiveTests) TestListPackages(c *gc.C) {
	pkgs, err := s.testClient.ListPackages(nil)
	c.Assert(err, gc.IsNil)
	c.Assert(pkgs, gc.NotNil)
	for _, pkg := range pkgs {
		c.Check(pkg.Name, gc.FitsTypeOf, string(""))
		c.Check(pkg.Memory, gc.FitsTypeOf, int(0))
		c.Check(pkg.Disk, gc.FitsTypeOf, int(0))
		c.Check(pkg.Swap, gc.FitsTypeOf, int(0))
		c.Check(pkg.VCPUs, gc.FitsTypeOf, int(0))
		c.Check(pkg.Default, gc.FitsTypeOf, bool(false))
		c.Check(pkg.Id, gc.FitsTypeOf, string(""))
		c.Check(pkg.Version, gc.FitsTypeOf, string(""))
		c.Check(pkg.Description, gc.FitsTypeOf, string(""))
		c.Check(pkg.Group, gc.FitsTypeOf, string(""))
	}
}

func (s *LiveTests) TestListPackagesWithFilter(c *gc.C) {
	filter := cloudapi.NewFilter()
	filter.Set("memory", "1024")
	pkgs, err := s.testClient.ListPackages(filter)
	c.Assert(err, gc.IsNil)
	c.Assert(pkgs, gc.NotNil)
	for _, pkg := range pkgs {
		c.Check(pkg.Name, gc.FitsTypeOf, string(""))
		c.Check(pkg.Memory, gc.Equals, 1024)
		c.Check(pkg.Disk, gc.FitsTypeOf, int(0))
		c.Check(pkg.Swap, gc.FitsTypeOf, int(0))
		c.Check(pkg.VCPUs, gc.FitsTypeOf, int(0))
		c.Check(pkg.Default, gc.FitsTypeOf, bool(false))
		c.Check(pkg.Id, gc.FitsTypeOf, string(""))
		c.Check(pkg.Version, gc.FitsTypeOf, string(""))
		c.Check(pkg.Description, gc.FitsTypeOf, string(""))
		c.Check(pkg.Group, gc.FitsTypeOf, string(""))
	}
}

func (s *LiveTests) TestGetPackageFromName(c *gc.C) {
	key, err := s.testClient.GetPackage(packageName)
	c.Assert(err, gc.IsNil)
	c.Assert(key, gc.NotNil)
	c.Assert(key, gc.DeepEquals, &cloudapi.Package{
		Name:        packageName,
		Memory:      1024,
		Disk:        33792,
		Swap:        2048,
		VCPUs:       0,
		Default:     false,
		Id:          packageID,
		Version:     "1.0.0",
		Description: "Standard 1 GB RAM 0.25 vCPU and bursting 33 GB Disk",
		Group:       "Standard",
	})
}

func (s *LiveTests) TestGetPackageFromId(c *gc.C) {
	key, err := s.testClient.GetPackage(packageID)
	c.Assert(err, gc.IsNil)
	c.Assert(key, gc.NotNil)
	c.Assert(key, gc.DeepEquals, &cloudapi.Package{
		Name:        packageName,
		Memory:      1024,
		Disk:        33792,
		Swap:        2048,
		VCPUs:       0,
		Default:     false,
		Id:          packageID,
		Version:     "1.0.0",
		Description: "Standard 1 GB RAM 0.25 vCPU and bursting 33 GB Disk",
		Group:       "Standard",
	})
}

// Images API
func (s *LiveTests) TestListImages(c *gc.C) {
	imgs, err := s.testClient.ListImages(nil)
	c.Assert(err, gc.IsNil)
	c.Assert(imgs, gc.NotNil)
	for _, img := range imgs {
		c.Check(img.Id, gc.FitsTypeOf, string(""))
		c.Check(img.Name, gc.FitsTypeOf, string(""))
		c.Check(img.OS, gc.FitsTypeOf, string(""))
		c.Check(img.Version, gc.FitsTypeOf, string(""))
		c.Check(img.Type, gc.FitsTypeOf, string(""))
		c.Check(img.Description, gc.FitsTypeOf, string(""))
		c.Check(img.Requirements, gc.FitsTypeOf, map[string]interface{}{"key": "value"})
		c.Check(img.Homepage, gc.FitsTypeOf, string(""))
		c.Check(img.PublishedAt, gc.FitsTypeOf, string(""))
		c.Check(img.Public, gc.FitsTypeOf, bool(true))
		c.Check(img.State, gc.FitsTypeOf, string(""))
		c.Check(img.Tags, gc.FitsTypeOf, map[string]string{"key": "value"})
		c.Check(img.EULA, gc.FitsTypeOf, string(""))
		c.Check(img.ACL, gc.FitsTypeOf, []string{"", ""})
	}
}

func (s *LiveTests) TestListImagesWithFilter(c *gc.C) {
	filter := cloudapi.NewFilter()
	filter.Set("os", "smartos")
	imgs, err := s.testClient.ListImages(filter)
	c.Assert(err, gc.IsNil)
	c.Assert(imgs, gc.NotNil)
	for _, img := range imgs {
		c.Check(img.Id, gc.FitsTypeOf, string(""))
		c.Check(img.Name, gc.FitsTypeOf, string(""))
		c.Check(img.OS, gc.Equals, "smartos")
		c.Check(img.Version, gc.FitsTypeOf, string(""))
		c.Check(img.Type, gc.FitsTypeOf, string(""))
		c.Check(img.Description, gc.FitsTypeOf, string(""))
		c.Check(img.Requirements, gc.FitsTypeOf, map[string]interface{}{"key": "value"})
		c.Check(img.Homepage, gc.FitsTypeOf, string(""))
		c.Check(img.PublishedAt, gc.FitsTypeOf, string(""))
		c.Check(img.Public, gc.FitsTypeOf, bool(true))
		c.Check(img.State, gc.FitsTypeOf, string(""))
		c.Check(img.Tags, gc.FitsTypeOf, map[string]string{"key": "value"})
		c.Check(img.EULA, gc.FitsTypeOf, string(""))
		c.Check(img.ACL, gc.FitsTypeOf, []string{"", ""})
	}
}

// TODO Add test for deleteImage, exportImage and CreateMachineFormIMage

func (s *LiveTests) TestGetImage(c *gc.C) {
	requirements := map[string]interface{}{}
	img, err := s.testClient.GetImage(imageID)
	c.Assert(err, gc.IsNil)
	c.Assert(img, gc.NotNil)
	c.Assert(img, gc.DeepEquals, &cloudapi.Image{
		Id:           imageID,
		Name:         "base",
		Version:      "13.1.0",
		OS:           "smartos",
		Type:         "smartmachine",
		Description:  "A 32-bit SmartOS image with just essential packages installed. Ideal for users who are comfortable with setting up their own environment and tools.",
		Requirements: requirements,
		PublishedAt:  "2013-04-26T15:16:02Z",
	})
}

// Datacenter API
func (s *LiveTests) TestListDatacenters(c *gc.C) {
	dcs, err := s.testClient.ListDatacenters()
	c.Assert(err, gc.IsNil)
	c.Assert(dcs, gc.HasLen, 4)
	c.Assert(dcs["us-west-1"], gc.Equals, "https://us-west-1.api.joyentcloud.com")
}

func (s *LiveTests) TestGetDatacenter(c *gc.C) {
	dc, err := s.testClient.GetDatacenter("us-west-1")
	c.Assert(err, gc.IsNil)
	c.Assert(dc, gc.Equals, "https://us-west-1.api.joyentcloud.com")
}

func (s *LiveTests) TestCreateMachine(c *gc.C) {
	testMachine := s.createMachine(c)
	defer s.deleteMachine(c, testMachine.Id)

	c.Assert(testMachine.Type, gc.Equals, "smartmachine")
	c.Assert(testMachine.Dataset, gc.Equals, "sdc:sdc:base:13.1.0")
	c.Assert(testMachine.Memory, gc.Equals, 1024)
	c.Assert(testMachine.Disk, gc.Equals, 33792)
	c.Assert(testMachine.Package, gc.Equals, packageName)
	c.Assert(testMachine.Image, gc.Equals, imageID)
}

func (s *LiveTests) TestCreateMachineWithTags(c *gc.C) {
	tags := map[string]string{"tag.tag1": "value1", "tag.tag2": "value2"}
	testMachine := s.createMachineWithTags(c, tags)
	defer s.deleteMachine(c, testMachine.Id)

	c.Assert(testMachine.Type, gc.Equals, "smartmachine")
	c.Assert(testMachine.Dataset, gc.Equals, "sdc:sdc:base:13.1.0")
	c.Assert(testMachine.Memory, gc.Equals, 1024)
	c.Assert(testMachine.Disk, gc.Equals, 33792)
	c.Assert(testMachine.Package, gc.Equals, packageName)
	c.Assert(testMachine.Image, gc.Equals, imageID)
	c.Assert(testMachine.Tags, gc.DeepEquals, map[string]string{"tag1": "value1", "tag2": "value2"})
}

func (s *LiveTests) TestListMachines(c *gc.C) {
	s.listMachines(c, nil)
}

func (s *LiveTests) TestListMachinesWithFilter(c *gc.C) {
	filter := cloudapi.NewFilter()
	filter.Set("memory", "1024")

	s.listMachines(c, filter)
}

func (s *LiveTests) TestCountMachines(c *gc.C) {
	testMachine := s.createMachine(c)
	defer s.deleteMachine(c, testMachine.Id)

	count, err := s.testClient.CountMachines()
	c.Assert(err, gc.IsNil)
	c.Assert(count >= 1, gc.Equals, true)
}

func (s *LiveTests) TestGetMachine(c *gc.C) {
	testMachine := s.createMachine(c)
	defer s.deleteMachine(c, testMachine.Id)

	machine, err := s.testClient.GetMachine(testMachine.Id)
	c.Assert(err, gc.IsNil)
	c.Assert(machine, gc.NotNil)
	c.Assert(machine.Equals(*testMachine), gc.Equals, true)
}

func (s *LiveTests) TestStopMachine(c *gc.C) {
	testMachine := s.createMachine(c)
	defer s.deleteMachine(c, testMachine.Id)

	err := s.testClient.StopMachine(testMachine.Id)
	c.Assert(err, gc.IsNil)
}

func (s *LiveTests) TestStartMachine(c *gc.C) {
	testMachine := s.createMachine(c)
	defer s.deleteMachine(c, testMachine.Id)

	err := s.testClient.StopMachine(testMachine.Id)
	c.Assert(err, gc.IsNil)

	// wait for machine to be stopped
	for !s.pollMachineState(c, testMachine.Id, "stopped") {
		time.Sleep(1 * time.Second)
	}

	err = s.testClient.StartMachine(testMachine.Id)
	c.Assert(err, gc.IsNil)
}

func (s *LiveTests) TestRebootMachine(c *gc.C) {
	testMachine := s.createMachine(c)
	defer s.deleteMachine(c, testMachine.Id)

	err := s.testClient.RebootMachine(testMachine.Id)
	c.Assert(err, gc.IsNil)
}

func (s *LiveTests) TestRenameMachine(c *gc.C) {
	testMachine := s.createMachine(c)
	defer s.deleteMachine(c, testMachine.Id)

	err := s.testClient.RenameMachine(testMachine.Id, "test-machine-renamed")
	c.Assert(err, gc.IsNil)

	renamed, err := s.testClient.GetMachine(testMachine.Id)
	c.Assert(err, gc.IsNil)
	c.Assert(renamed.Name, gc.Equals, "test-machine-renamed")
}

func (s *LiveTests) TestResizeMachine(c *gc.C) {
	testMachine := s.createMachine(c)
	defer s.deleteMachine(c, testMachine.Id)

	err := s.testClient.ResizeMachine(testMachine.Id, "g3-standard-1.75-smartos")
	c.Assert(err, gc.IsNil)

	resized, err := s.testClient.GetMachine(testMachine.Id)
	c.Assert(err, gc.IsNil)
	c.Assert(resized.Package, gc.Equals, "g3-standard-1.75-smartos")
}

func (s *LiveTests) TestListMachinesFirewallRules(c *gc.C) {
	testMachine := s.createMachine(c)
	defer s.deleteMachine(c, testMachine.Id)

	fwRules, err := s.testClient.ListMachineFirewallRules(testMachine.Id)
	c.Assert(err, gc.IsNil)
	c.Assert(fwRules, gc.NotNil)
}

func (s *LiveTests) TestEnableFirewallMachine(c *gc.C) {
	testMachine := s.createMachine(c)
	defer s.deleteMachine(c, testMachine.Id)

	err := s.testClient.EnableFirewallMachine(testMachine.Id)
	c.Assert(err, gc.IsNil)
}

func (s *LiveTests) TestDisableFirewallMachine(c *gc.C) {
	testMachine := s.createMachine(c)
	defer s.deleteMachine(c, testMachine.Id)

	err := s.testClient.DisableFirewallMachine(testMachine.Id)
	c.Assert(err, gc.IsNil)
}

func (s *LiveTests) TestCreateMachineSnapshot(c *gc.C) {
	testMachine := s.createMachine(c)
	defer s.deleteMachine(c, testMachine.Id)

	s.createMachineSnapshot(c, testMachine.Id)
}

func (s *LiveTests) TestStartMachineFromShapshot(c *gc.C) {
	testMachine := s.createMachine(c)
	defer s.deleteMachine(c, testMachine.Id)
	snapshotName := s.createMachineSnapshot(c, testMachine.Id)

	err := s.testClient.StopMachine(testMachine.Id)
	c.Assert(err, gc.IsNil)

	// wait for machine to be stopped
	for !s.pollMachineState(c, testMachine.Id, "stopped") {
		time.Sleep(1 * time.Second)
	}

	err = s.testClient.StartMachineFromSnapshot(testMachine.Id, snapshotName)
	c.Assert(err, gc.IsNil)
}

func (s *LiveTests) TestListMachineSnapshots(c *gc.C) {
	testMachine := s.createMachine(c)
	defer s.deleteMachine(c, testMachine.Id)
	s.createMachineSnapshot(c, testMachine.Id)

	snapshots, err := s.testClient.ListMachineSnapshots(testMachine.Id)
	c.Assert(err, gc.IsNil)
	c.Assert(snapshots, gc.HasLen, 1)
}

func (s *LiveTests) TestGetMachineSnapshot(c *gc.C) {
	testMachine := s.createMachine(c)
	defer s.deleteMachine(c, testMachine.Id)
	snapshotName := s.createMachineSnapshot(c, testMachine.Id)

	snapshot, err := s.testClient.GetMachineSnapshot(testMachine.Id, snapshotName)
	c.Assert(err, gc.IsNil)
	c.Assert(snapshot, gc.NotNil)
	c.Assert(snapshot, gc.DeepEquals, &cloudapi.Snapshot{Name: snapshotName, State: "created"})
}

func (s *LiveTests) TestDeleteMachineSnapshot(c *gc.C) {
	testMachine := s.createMachine(c)
	defer s.deleteMachine(c, testMachine.Id)
	snapshotName := s.createMachineSnapshot(c, testMachine.Id)

	err := s.testClient.DeleteMachineSnapshot(testMachine.Id, snapshotName)
	c.Assert(err, gc.IsNil)
}

func (s *LiveTests) TestUpdateMachineMetadata(c *gc.C) {
	testMachine := s.createMachine(c)
	defer s.deleteMachine(c, testMachine.Id)

	md, err := s.testClient.UpdateMachineMetadata(testMachine.Id, map[string]string{"test-metadata": "md value", "test": "test"})
	metadata := map[string]interface{}{"root_authorized_keys": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCyucy41MNcPxEkNUneeRT0j4mXX5zzW4cFYZ0G/Wpqrb/A+JZV6xlwmAwsGPAvebeEp40CSc0gzauR0nsQ+0Hefdp+dHdEEZlZ7WhedknponA8cQURU38cmTnGweaw2B0+vkULo5AUPAjv0Y1nGPZVlKWNeR6NJhq51pEtj4eLYCJ+kylHEIjQbP5Q1LQHxxotoY29N/xMx+ZVYGprHUJ5ihMOC1nrz2kqUjbCvvMLC0yzAI3vfKtL14BQs9Aq9ggl9oZZylmsgy9CnrPa5t98/wqG+snGyrPSL27km0rll1Jz6xcraGkXQP0adFJxw7mFrXItAt6TUyAuLoohhjHd daniele@lightman.local\n",
		"origin": "cloudapi", "creator_uuid": "ff0c4a2b-f89a-4f14-81ee-5b31e7c89ece", "test": "test", "test-metadata": "md value",
		"context": map[string]interface{}{"caller": map[string]interface{}{"type": "signature", "ip": "127.0.0.1", "keyId": "/dstroppa/keys/12:c3:a7:cb:a2:29:e2:90:88:3f:04:53:3b:4e:75:40"},
			"params": map[string]interface{}{"account": "dstroppa", "machine": testMachine.Id, "test": "test", "test-metadata": "md value"}}}
	c.Assert(err, gc.IsNil)
	c.Assert(md, gc.NotNil)
	c.Assert(md, gc.DeepEquals, metadata)
}

func (s *LiveTests) TestGetMachineMetadata(c *gc.C) {
	testMachine := s.createMachine(c)
	defer s.deleteMachine(c, testMachine.Id)

	md, err := s.testClient.GetMachineMetadata(testMachine.Id)
	c.Assert(err, gc.IsNil)
	c.Assert(md, gc.NotNil)
	c.Assert(md, gc.HasLen, 5)
}

func (s *LiveTests) TestDeleteMachineMetadata(c *gc.C) {
	testMachine := s.createMachine(c)
	defer s.deleteMachine(c, testMachine.Id)

	_, err := s.testClient.UpdateMachineMetadata(testMachine.Id, map[string]string{"test-metadata": "md value"})
	c.Assert(err, gc.IsNil)
	// allow update to propagate
	time.Sleep(10 * time.Second)

	err = s.testClient.DeleteMachineMetadata(testMachine.Id, "test-metadata")
	c.Assert(err, gc.IsNil)
}

func (s *LiveTests) TestDeleteAllMachineMetadata(c *gc.C) {
	testMachine := s.createMachine(c)
	defer s.deleteMachine(c, testMachine.Id)

	err := s.testClient.DeleteAllMachineMetadata(testMachine.Id)
	c.Assert(err, gc.IsNil)
}

func (s *LiveTests) TestAddMachineTags(c *gc.C) {
	testMachine := s.createMachine(c)
	defer s.deleteMachine(c, testMachine.Id)

	machineTags := map[string]string{"test-tag": "test-tag-value", "test": "test", "tag1": "tagtag"}
	tags, err := s.testClient.AddMachineTags(testMachine.Id, map[string]string{"test-tag": "test-tag-value", "test": "test", "tag1": "tagtag"})
	c.Assert(err, gc.IsNil)
	c.Assert(tags, gc.NotNil)
	c.Assert(tags, gc.DeepEquals, machineTags)
}

func (s *LiveTests) TestReplaceMachineTags(c *gc.C) {
	testMachine := s.createMachine(c)
	defer s.deleteMachine(c, testMachine.Id)

	machineTags := map[string]string{"origin": "cloudapi", "creator_uuid": "ff0c4a2b-f89a-4f14-81ee-5b31e7c89ece", "test-tag": "test-tag-value", "test": "test tag", "tag1": "tag2"}
	tags, err := s.testClient.ReplaceMachineTags(testMachine.Id, map[string]string{"test-tag": "test-tag-value", "test": "test tag", "tag1": "tag2"})
	c.Assert(err, gc.IsNil)
	c.Assert(tags, gc.NotNil)
	c.Assert(tags, gc.DeepEquals, machineTags)
}

func (s *LiveTests) TestListMachineTags(c *gc.C) {
	testMachine := s.createMachine(c)
	defer s.deleteMachine(c, testMachine.Id)

	tags, err := s.testClient.ListMachineTags(testMachine.Id)
	c.Assert(err, gc.IsNil)
	c.Assert(tags, gc.NotNil)
	c.Assert(tags, gc.HasLen, 5)
}

func (s *LiveTests) TestGetMachineTag(c *gc.C) {
	testMachine := s.createMachine(c)
	defer s.deleteMachine(c, testMachine.Id)

	_, err := s.testClient.AddMachineTags(testMachine.Id, map[string]string{"test-tag": "test-tag-value"})
	c.Assert(err, gc.IsNil)
	// allow update to propagate
	time.Sleep(15 * time.Second)

	tag, err := s.testClient.GetMachineTag(testMachine.Id, "test-tag")
	c.Assert(err, gc.IsNil)
	c.Assert(tag, gc.NotNil)
	c.Assert(tag, gc.Equals, "test-tag-value")
}

func (s *LiveTests) TestDeleteMachineTag(c *gc.C) {
	testMachine := s.createMachine(c)
	defer s.deleteMachine(c, testMachine.Id)

	_, err := s.testClient.AddMachineTags(testMachine.Id, map[string]string{"test-tag": "test-tag-value"})
	c.Assert(err, gc.IsNil)
	// allow update to propagate
	time.Sleep(15 * time.Second)

	err = s.testClient.DeleteMachineTag(testMachine.Id, "test-tag")
	c.Assert(err, gc.IsNil)
}

func (s *LiveTests) TestDeleteMachineTags(c *gc.C) {
	testMachine := s.createMachine(c)
	defer s.deleteMachine(c, testMachine.Id)

	err := s.testClient.DeleteMachineTags(testMachine.Id)
	c.Assert(err, gc.IsNil)
}

func (s *LiveTests) TestMachineAudit(c *gc.C) {
	testMachine := s.createMachine(c)
	defer s.deleteMachine(c, testMachine.Id)

	actions, err := s.testClient.MachineAudit(testMachine.Id)
	c.Assert(err, gc.IsNil)
	c.Assert(actions, gc.NotNil)
	c.Assert(len(actions) > 0, gc.Equals, true)
}

func (s *LiveTests) TestDeleteMachine(c *gc.C) {
	testMachine := s.createMachine(c)

	s.deleteMachine(c, testMachine.Id)
}

// Analytics API

// FirewallRules API

func (s *LiveTests) TestCreateFirewallRule(c *gc.C) {
	testFwRule := s.createFirewallRule(c)

	// cleanup
	s.deleteFwRule(c, testFwRule.Id)
}

func (s *LiveTests) TestListFirewallRules(c *gc.C) {
	testFwRule := s.createFirewallRule(c)
	defer s.deleteFwRule(c, testFwRule.Id)

	rules, err := s.testClient.ListFirewallRules()
	c.Assert(err, gc.IsNil)
	c.Assert(rules, gc.NotNil)
}

func (s *LiveTests) TestGetFirewallRule(c *gc.C) {
	testFwRule := s.createFirewallRule(c)
	defer s.deleteFwRule(c, testFwRule.Id)

	fwRule, err := s.testClient.GetFirewallRule(testFwRule.Id)
	c.Assert(err, gc.IsNil)
	c.Assert(fwRule, gc.NotNil)
	c.Assert((*fwRule), gc.DeepEquals, (*testFwRule))
}

func (s *LiveTests) TestUpdateFirewallRule(c *gc.C) {
	testFwRule := s.createFirewallRule(c)
	defer s.deleteFwRule(c, testFwRule.Id)

	fwRule, err := s.testClient.UpdateFirewallRule(testFwRule.Id, cloudapi.CreateFwRuleOpts{Rule: testUpdatedFwRule})
	c.Assert(err, gc.IsNil)
	c.Assert(fwRule, gc.NotNil)
	c.Assert(fwRule.Rule, gc.Equals, testUpdatedFwRule)
}

func (s *LiveTests) TestEnableFirewallRule(c *gc.C) {
	testFwRule := s.createFirewallRule(c)
	defer s.deleteFwRule(c, testFwRule.Id)

	fwRule, err := s.testClient.EnableFirewallRule((*testFwRule).Id)
	c.Assert(err, gc.IsNil)
	c.Assert(fwRule, gc.NotNil)
}

func (s *LiveTests) TestListFirewallRuleMachines(c *gc.C) {
	testFwRule := s.createFirewallRule(c)
	defer s.deleteFwRule(c, testFwRule.Id)

	machines, err := s.testClient.ListFirewallRuleMachines((*testFwRule).Id)
	c.Assert(err, gc.IsNil)
	c.Assert(machines, gc.NotNil)
}

func (s *LiveTests) TestDisableFirewallRule(c *gc.C) {
	testFwRule := s.createFirewallRule(c)
	defer s.deleteFwRule(c, testFwRule.Id)

	fwRule, err := s.testClient.DisableFirewallRule((*testFwRule).Id)
	c.Assert(err, gc.IsNil)
	c.Assert(fwRule, gc.NotNil)
}

func (s *LiveTests) TestDeleteFirewallRule(c *gc.C) {
	testFwRule := s.createFirewallRule(c)

	s.deleteFwRule(c, testFwRule.Id)
}

// Networks API
func (s *LiveTests) TestListNetworks(c *gc.C) {
	nets, err := s.testClient.ListNetworks()
	c.Assert(err, gc.IsNil)
	c.Assert(nets, gc.NotNil)
}

func (s *LiveTests) TestGetNetwork(c *gc.C) {
	net, err := s.testClient.GetNetwork(networkID)
	c.Assert(err, gc.IsNil)
	c.Assert(net, gc.NotNil)
	c.Assert(net, gc.DeepEquals, &cloudapi.Network{
		Id:          networkID,
		Name:        "Joyent-SDC-Public",
		Public:      true,
		Description: "",
	})
}
