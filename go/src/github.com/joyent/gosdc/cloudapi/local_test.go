//
// gosdc - Go library to interact with the Joyent CloudAPI
//
// Copyright (c) Joyent Inc.
//

package cloudapi_test

import (
	"io/ioutil"
	"log"
	"net/http"
	"net/http/httptest"
	"os"
	"strings"
	"time"

	gc "launchpad.net/gocheck"

	"github.com/joyent/gocommon/client"
	"github.com/joyent/gosdc/cloudapi"
	lc "github.com/joyent/gosdc/localservices/cloudapi"
	"github.com/joyent/gosign/auth"
	"github.com/julienschmidt/httprouter"
)

var privateKey []byte

func registerLocalTests(keyName string) {
	var localKeyFile string
	if keyName == "" {
		localKeyFile = os.Getenv("HOME") + "/.ssh/id_rsa"
	} else {
		localKeyFile = keyName
	}
	privateKey, _ = ioutil.ReadFile(localKeyFile)

	gc.Suite(&LocalTests{})
}

type LocalTests struct {
	//LocalTests
	creds      *auth.Credentials
	testClient *cloudapi.Client
	Server     *httptest.Server
	Mux        *httprouter.Router
	oldHandler http.Handler
	cloudapi   *lc.CloudAPI
}

func (s *LocalTests) SetUpSuite(c *gc.C) {
	// Set up the HTTP server.
	s.Server = httptest.NewServer(nil)
	s.oldHandler = s.Server.Config.Handler
	s.Mux = httprouter.New()
	s.Server.Config.Handler = s.Mux

	// Set up a Joyent CloudAPI service.
	authentication, err := auth.NewAuth("localtest", string(privateKey), "rsa-sha256")
	c.Assert(err, gc.IsNil)

	s.creds = &auth.Credentials{
		UserAuthentication: authentication,
		SdcKeyId:           "",
		SdcEndpoint:        auth.Endpoint{URL: s.Server.URL},
	}
	s.cloudapi = lc.New(s.creds.SdcEndpoint.URL, s.creds.UserAuthentication.User)
	s.cloudapi.SetupHTTP(s.Mux)
}

func (s *LocalTests) TearDownSuite(c *gc.C) {
	s.Mux = nil
	s.Server.Config.Handler = s.oldHandler
	s.Server.Close()
}

func (s *LocalTests) SetUpTest(c *gc.C) {
	client := client.NewClient(s.creds.SdcEndpoint.URL, cloudapi.DefaultAPIVersion, s.creds, log.New(os.Stderr, "", log.LstdFlags))
	c.Assert(client, gc.NotNil)
	s.testClient = cloudapi.New(client)
	c.Assert(s.testClient, gc.NotNil)
}

// Helper method to create a test key in the user account
func (s *LocalTests) createKey(c *gc.C) {
	key, err := s.testClient.CreateKey(cloudapi.CreateKeyOpts{Name: "fake-key", Key: testKey})
	c.Assert(err, gc.IsNil)
	c.Assert(key, gc.DeepEquals, &cloudapi.Key{Name: "fake-key", Fingerprint: "", Key: testKey})
}

func (s *LocalTests) deleteKey(c *gc.C) {
	err := s.testClient.DeleteKey("fake-key")
	c.Assert(err, gc.IsNil)
}

// Helper method to create a test virtual machine in the user account
func (s *LocalTests) createMachine(c *gc.C) *cloudapi.Machine {
	machine, err := s.testClient.CreateMachine(cloudapi.CreateMachineOpts{Package: localPackageName, Image: localImageID})
	c.Assert(err, gc.IsNil)
	c.Assert(machine, gc.NotNil)

	// wait for machine to be provisioned
	for !s.pollMachineState(c, machine.Id, "running") {
		time.Sleep(1 * time.Second)
	}

	return machine
}

// Helper method to test the state of a given VM
func (s *LocalTests) pollMachineState(c *gc.C, machineId, state string) bool {
	machineConfig, err := s.testClient.GetMachine(machineId)
	c.Assert(err, gc.IsNil)
	return strings.EqualFold(machineConfig.State, state)
}

// Helper method to delete a test virtual machine once the test has executed
func (s *LocalTests) deleteMachine(c *gc.C, machineId string) {
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
func (s *LocalTests) listMachines(c *gc.C, filter *cloudapi.Filter) {
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
		c.Fatalf("Obtained machines [%v] do not contain test machine [%v]", machines, *testMachine)
	}
}

// Helper method to create a test firewall rule
func (s *LocalTests) createFirewallRule(c *gc.C) *cloudapi.FirewallRule {
	fwRule, err := s.testClient.CreateFirewallRule(cloudapi.CreateFwRuleOpts{Enabled: false, Rule: testFwRule})
	c.Assert(err, gc.IsNil)
	c.Assert(fwRule, gc.NotNil)
	c.Assert(fwRule.Rule, gc.Equals, testFwRule)
	c.Assert(fwRule.Enabled, gc.Equals, false)
	time.Sleep(10 * time.Second)

	return fwRule
}

// Helper method to a test firewall rule
func (s *LocalTests) deleteFwRule(c *gc.C, fwRuleId string) {
	err := s.testClient.DeleteFirewallRule(fwRuleId)
	c.Assert(err, gc.IsNil)
}
