//
// gosdc - Go library to interact with the Joyent CloudAPI
//
// CloudAPI double testing service - HTTP API tests
//
// Copyright (c) Joyent Inc.
//

package cloudapi_test

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"path"
	"strconv"
	"strings"

	gc "launchpad.net/gocheck"

	"github.com/joyent/gocommon/testing"
	"github.com/joyent/gosdc/cloudapi"
	lc "github.com/joyent/gosdc/localservices/cloudapi"
)

type CloudAPIHTTPSuite struct {
	testing.HTTPSuite
	service *lc.CloudAPI
}

var _ = gc.Suite(&CloudAPIHTTPSuite{})

type CloudAPIHTTPSSuite struct {
	testing.HTTPSuite
	service *lc.CloudAPI
}

var _ = gc.Suite(&CloudAPIHTTPSSuite{HTTPSuite: testing.HTTPSuite{UseTLS: true}})

func (s *CloudAPIHTTPSuite) SetUpSuite(c *gc.C) {
	s.HTTPSuite.SetUpSuite(c)
	c.Assert(s.Server.URL[:7], gc.Equals, "http://")
	s.service = lc.New(s.Server.URL, testUserAccount)
}

func (s *CloudAPIHTTPSuite) TearDownSuite(c *gc.C) {
	s.HTTPSuite.TearDownSuite(c)
}

func (s *CloudAPIHTTPSuite) SetUpTest(c *gc.C) {
	s.HTTPSuite.SetUpTest(c)
	s.service.SetupHTTP(s.Mux)
}

func (s *CloudAPIHTTPSuite) TearDownTest(c *gc.C) {
	s.HTTPSuite.TearDownTest(c)
}

// assertJSON asserts the passed http.Response's body can be
// unmarshalled into the given expected object, populating it with the
// successfully parsed data.
func assertJSON(c *gc.C, resp *http.Response, expected interface{}) {
	body, err := ioutil.ReadAll(resp.Body)
	defer resp.Body.Close()
	c.Assert(err, gc.IsNil)
	err = json.Unmarshal(body, &expected)
	c.Assert(err, gc.IsNil)
}

// assertBody asserts the passed http.Response's body matches the
// expected response, replacing any variables in the expected body.
func assertBody(c *gc.C, resp *http.Response, expected *lc.ErrorResponse) {
	body, err := ioutil.ReadAll(resp.Body)
	defer resp.Body.Close()
	c.Assert(err, gc.IsNil)
	expBody := expected.Body
	// cast to string for easier asserts debugging
	c.Assert(string(body), gc.Equals, string(expBody))
}

// sendRequest constructs an HTTP request from the parameters and
// sends it, returning the response or an error.
func (s *CloudAPIHTTPSuite) sendRequest(method, path string, body []byte, headers http.Header) (*http.Response, error) {
	if headers == nil {
		headers = make(http.Header)
	}
	requestURL := "http://" + s.service.Hostname + strings.TrimLeft(path, "/")
	req, err := http.NewRequest(method, requestURL, bytes.NewReader(body))
	if err != nil {
		return nil, err
	}
	req.Close = true
	for header, values := range headers {
		for _, value := range values {
			req.Header.Add(header, value)
		}
	}
	// workaround for https://code.google.com/p/go/issues/detail?id=4454
	req.Header.Set("Content-Length", strconv.Itoa(len(body)))
	return http.DefaultClient.Do(req)
}

// jsonRequest serializes the passed body object to JSON and sends a
// the request with authRequest().
func (s *CloudAPIHTTPSuite) jsonRequest(method, path string, body interface{}, headers http.Header) (*http.Response, error) {
	jsonBody, err := json.Marshal(body)
	if err != nil {
		return nil, err
	}
	return s.sendRequest(method, path, jsonBody, headers)
}

// Helpers
func (s *CloudAPIHTTPSuite) createKey(c *gc.C, keyName, key string) *cloudapi.Key {
	opts := cloudapi.CreateKeyOpts{Name: keyName, Key: key}
	optsByte, err := json.Marshal(opts)
	c.Assert(err, gc.IsNil)
	resp, err := s.sendRequest("POST", path.Join(testUserAccount, "keys"), optsByte, nil)
	c.Assert(err, gc.IsNil)
	c.Assert(resp.StatusCode, gc.Equals, http.StatusCreated)
	k := &cloudapi.Key{}
	assertJSON(c, resp, k)

	return k
}

func (s *CloudAPIHTTPSuite) deleteKey(c *gc.C, keyName string) {
	resp, err := s.sendRequest("DELETE", path.Join(testUserAccount, "keys", keyName), nil, nil)
	c.Assert(err, gc.IsNil)
	c.Assert(resp.StatusCode, gc.Equals, http.StatusNoContent)
}

func (s *CloudAPIHTTPSuite) createMachine(c *gc.C, name, pkg, image string, metadata, tags map[string]string) *cloudapi.Machine {
	opts := cloudapi.CreateMachineOpts{Name: name, Image: image, Package: pkg, Tags: tags, Metadata: metadata}
	optsByte, err := json.Marshal(opts)
	c.Assert(err, gc.IsNil)
	resp, err := s.sendRequest("POST", path.Join(testUserAccount, "machines"), optsByte, nil)
	c.Assert(err, gc.IsNil)
	c.Assert(resp.StatusCode, gc.Equals, http.StatusCreated)
	m := &cloudapi.Machine{}
	assertJSON(c, resp, m)

	return m
}

func (s *CloudAPIHTTPSuite) getMachine(c *gc.C, machineId string, expected *cloudapi.Machine) {
	resp, err := s.sendRequest("GET", path.Join(testUserAccount, "machines", machineId), nil, nil)
	c.Assert(err, gc.IsNil)
	c.Assert(resp.StatusCode, gc.Equals, http.StatusOK)
	assertJSON(c, resp, expected)
}

func (s *CloudAPIHTTPSuite) deleteMachine(c *gc.C, machineId string) {
	resp, err := s.sendRequest("POST", fmt.Sprintf("%s?action=stop", path.Join(testUserAccount, "machines", machineId)), nil, nil)
	c.Assert(err, gc.IsNil)
	c.Assert(resp.StatusCode, gc.Equals, http.StatusAccepted)
	resp, err = s.sendRequest("DELETE", path.Join(testUserAccount, "machines", machineId), nil, nil)
	c.Assert(err, gc.IsNil)
	c.Assert(resp.StatusCode, gc.Equals, http.StatusNoContent)
}

// Helper method to create a test firewall rule
func (s *CloudAPIHTTPSuite) createFirewallRule(c *gc.C) *cloudapi.FirewallRule {
	opts := cloudapi.CreateFwRuleOpts{Rule: testFwRule, Enabled: true}
	optsByte, err := json.Marshal(opts)
	c.Assert(err, gc.IsNil)
	resp, err := s.sendRequest("POST", path.Join(testUserAccount, "fwrules"), optsByte, nil)
	c.Assert(err, gc.IsNil)
	c.Assert(resp.StatusCode, gc.Equals, http.StatusCreated)
	r := &cloudapi.FirewallRule{}
	assertJSON(c, resp, r)

	return r
}

// Helper method to a test firewall rule
func (s *CloudAPIHTTPSuite) deleteFwRule(c *gc.C, fwRuleId string) {
	resp, err := s.sendRequest("DELETE", path.Join(testUserAccount, "fwrules", fwRuleId), nil, nil)
	c.Assert(err, gc.IsNil)
	c.Assert(resp.StatusCode, gc.Equals, http.StatusNoContent)
}

// SimpleTest defines a simple request without a body and expected response.
type SimpleTest struct {
	method  string
	url     string
	headers http.Header
	expect  *lc.ErrorResponse
}

func (s *CloudAPIHTTPSuite) simpleTests() []SimpleTest {
	var simpleTests = []SimpleTest{
		{
			method:  "GET",
			url:     "/",
			headers: make(http.Header),
			expect:  lc.ErrNotFound,
		},
		{
			method:  "POST",
			url:     "/",
			headers: make(http.Header),
			expect:  lc.ErrNotFound,
		},
		{
			method:  "DELETE",
			url:     "/",
			headers: make(http.Header),
			expect:  lc.ErrNotFound,
		},
		{
			method:  "PUT",
			url:     "/",
			headers: make(http.Header),
			expect:  lc.ErrNotFound,
		},
		{
			method:  "GET",
			url:     "/any",
			headers: make(http.Header),
			expect:  lc.ErrNotFound,
		},
		{
			method:  "POST",
			url:     "/any",
			headers: make(http.Header),
			expect:  lc.ErrNotFound,
		},
		{
			method:  "DELETE",
			url:     "/any",
			headers: make(http.Header),
			expect:  lc.ErrNotFound,
		},
		{
			method:  "PUT",
			url:     "/any",
			headers: make(http.Header),
			expect:  lc.ErrNotFound,
		},
		{
			method:  "PUT",
			url:     path.Join(testUserAccount, "keys"),
			headers: make(http.Header),
			expect:  lc.ErrNotAllowed,
		},
		{
			method:  "PUT",
			url:     path.Join(testUserAccount, "images"),
			headers: make(http.Header),
			expect:  lc.ErrNotAllowed,
		},
		{
			method:  "POST",
			url:     path.Join(testUserAccount, "packages"),
			headers: make(http.Header),
			expect:  lc.ErrNotAllowed,
		},
		{
			method:  "PUT",
			url:     path.Join(testUserAccount, "packages"),
			headers: make(http.Header),
			expect:  lc.ErrNotAllowed,
		},
		{
			method:  "DELETE",
			url:     path.Join(testUserAccount, "packages"),
			headers: make(http.Header),
			expect:  lc.ErrNotAllowed,
		},
		{
			method:  "PUT",
			url:     path.Join(testUserAccount, "machines"),
			headers: make(http.Header),
			expect:  lc.ErrNotAllowed,
		},
		{
			method:  "PUT",
			url:     path.Join(testUserAccount, "fwrules"),
			headers: make(http.Header),
			expect:  lc.ErrNotAllowed,
		},
		{
			method:  "POST",
			url:     path.Join(testUserAccount, "networks"),
			headers: make(http.Header),
			expect:  lc.ErrNotAllowed,
		},
		{
			method:  "PUT",
			url:     path.Join(testUserAccount, "networks"),
			headers: make(http.Header),
			expect:  lc.ErrNotAllowed,
		},
		{
			method:  "DELETE",
			url:     path.Join(testUserAccount, "networks"),
			headers: make(http.Header),
			expect:  lc.ErrNotAllowed,
		},
	}
	return simpleTests
}

func (s *CloudAPIHTTPSuite) TestSimpleRequestTests(c *gc.C) {
	simpleTests := s.simpleTests()
	for i, t := range simpleTests {
		c.Logf("#%d. %s %s -> %d", i, t.method, t.url, t.expect.Code)
		if t.headers == nil {
			t.headers = make(http.Header)
		}
		var (
			resp *http.Response
			err  error
		)
		resp, err = s.sendRequest(t.method, t.url, nil, t.headers)
		c.Assert(err, gc.IsNil)
		c.Assert(resp.StatusCode, gc.Equals, t.expect.Code)
		assertBody(c, resp, t.expect)
	}
}

// Tests for Keys API
func (s *CloudAPIHTTPSuite) TestListKeys(c *gc.C) {
	var expected []cloudapi.Key
	k := s.createKey(c, testKeyName, testKey)
	defer s.deleteKey(c, testKeyName)

	resp, err := s.sendRequest("GET", path.Join(testUserAccount, "keys"), nil, nil)
	c.Assert(err, gc.IsNil)
	c.Assert(resp.StatusCode, gc.Equals, http.StatusOK)
	assertJSON(c, resp, &expected)
	for _, key := range expected {
		if c.Check(&key, gc.DeepEquals, k) {
			c.SucceedNow()
		}
	}
	c.Fatalf("Obtained keys [%s] do not contain test key [%s]", expected, k)
}

func (s *CloudAPIHTTPSuite) TestGetKey(c *gc.C) {
	var expected cloudapi.Key
	k := s.createKey(c, testKeyName, testKey)
	defer s.deleteKey(c, testKeyName)

	resp, err := s.sendRequest("GET", path.Join(testUserAccount, "keys", testKeyName), nil, nil)
	c.Assert(err, gc.IsNil)
	c.Assert(resp.StatusCode, gc.Equals, http.StatusOK)
	assertJSON(c, resp, &expected)
	c.Assert(&expected, gc.DeepEquals, k)
}

func (s *CloudAPIHTTPSuite) TestCreateKey(c *gc.C) {
	k := s.createKey(c, testKeyName, testKey)
	defer s.deleteKey(c, testKeyName)

	c.Assert(k.Name, gc.Equals, testKeyName)
	c.Assert(k.Key, gc.Equals, testKey)
}

func (s *CloudAPIHTTPSuite) TestDeleteKey(c *gc.C) {
	s.createKey(c, testKeyName, testKey)
	s.deleteKey(c, testKeyName)
}

// Tests for Images API
func (s *CloudAPIHTTPSuite) TestListImages(c *gc.C) {
	var expected []cloudapi.Image

	resp, err := s.sendRequest("GET", path.Join(testUserAccount, "images"), nil, nil)
	c.Assert(err, gc.IsNil)
	c.Assert(resp.StatusCode, gc.Equals, http.StatusOK)
	assertJSON(c, resp, &expected)
	c.Assert(len(expected), gc.Equals, 6)
}

func (s *CloudAPIHTTPSuite) TestGetImage(c *gc.C) {
	var expected cloudapi.Image

	resp, err := s.sendRequest("GET", path.Join(testUserAccount, "images", testImage), nil, nil)
	c.Assert(err, gc.IsNil)
	c.Assert(resp.StatusCode, gc.Equals, http.StatusOK)
	assertJSON(c, resp, &expected)
	c.Assert(expected.Id, gc.Equals, "11223344-0a0a-ff99-11bb-0a1b2c3d4e5f")
	c.Assert(expected.Name, gc.Equals, "ubuntu12.04")
	c.Assert(expected.OS, gc.Equals, "linux")
	c.Assert(expected.Version, gc.Equals, "2.3.1")
	c.Assert(expected.Type, gc.Equals, "virtualmachine")
	c.Assert(expected.Description, gc.Equals, "Test Ubuntu 12.04 image (64 bit)")
	c.Assert(expected.PublishedAt, gc.Equals, "2014-01-20T16:12:31Z")
	c.Assert(expected.Public, gc.Equals, true)
	c.Assert(expected.State, gc.Equals, "active")
}

// Tests for Packages API
func (s *CloudAPIHTTPSuite) TestListPackages(c *gc.C) {
	var expected []cloudapi.Package

	resp, err := s.sendRequest("GET", path.Join(testUserAccount, "packages"), nil, nil)
	c.Assert(err, gc.IsNil)
	c.Assert(resp.StatusCode, gc.Equals, http.StatusOK)
	assertJSON(c, resp, &expected)
	c.Assert(len(expected), gc.Equals, 4)
}

func (s *CloudAPIHTTPSuite) TestGetPackage(c *gc.C) {
	var expected cloudapi.Package

	resp, err := s.sendRequest("GET", path.Join(testUserAccount, "packages", testPackage), nil, nil)
	c.Assert(err, gc.IsNil)
	c.Assert(resp.StatusCode, gc.Equals, http.StatusOK)
	assertJSON(c, resp, &expected)
	c.Assert(expected.Name, gc.Equals, "Small")
	c.Assert(expected.Memory, gc.Equals, 1024)
	c.Assert(expected.Disk, gc.Equals, 16384)
	c.Assert(expected.Swap, gc.Equals, 2048)
	c.Assert(expected.VCPUs, gc.Equals, 1)
	c.Assert(expected.Default, gc.Equals, true)
	c.Assert(expected.Id, gc.Equals, "11223344-1212-abab-3434-aabbccddeeff")
	c.Assert(expected.Version, gc.Equals, "1.0.2")
}

// Tests for Machines API
func (s *CloudAPIHTTPSuite) TestListMachines(c *gc.C) {
	var expected []cloudapi.Machine
	m := s.createMachine(c, testMachineName, testPackage, testImage, nil, nil)
	defer s.deleteMachine(c, m.Id)

	resp, err := s.sendRequest("GET", path.Join(testUserAccount, "machines"), nil, nil)
	c.Assert(err, gc.IsNil)
	c.Assert(resp.StatusCode, gc.Equals, http.StatusOK)
	assertJSON(c, resp, &expected)
	for _, machine := range expected {
		if machine.Id == m.Id {
			c.SucceedNow()
		}
	}
	c.Fatalf("Obtained machine [%s] do not contain test machine [%s]", expected, m)
}

/*func (s *CloudAPIHTTPSuite) TestCountMachines(c *gc.C) {
	m := s.createMachine(c, testMachineName, testPackage, testImage, nil, nil)
	defer s.deleteMachine(c, m.Id)

	resp, err := s.sendRequest("HEAD", path.Join(testUserAccount, "machines"), nil, nil)
	c.Assert(err, gc.IsNil)
	c.Assert(resp.StatusCode, gc.Equals, http.StatusOK)
	fmt.Printf("Got response %q\n", resp)
	assertBody(c, resp, &lc.ErrorResponse{Body: "1"})
} */

func (s *CloudAPIHTTPSuite) TestGetMachine(c *gc.C) {
	var expected cloudapi.Machine
	m := s.createMachine(c, testMachineName, testPackage, testImage, nil, nil)
	defer s.deleteMachine(c, m.Id)

	s.getMachine(c, m.Id, &expected)
	c.Assert(expected.Name, gc.Equals, testMachineName)
	c.Assert(expected.Package, gc.Equals, testPackage)
	c.Assert(expected.Image, gc.Equals, testImage)
}

func (s *CloudAPIHTTPSuite) TestCreateMachine(c *gc.C) {
	m := s.createMachine(c, testMachineName, testPackage, testImage, nil, nil)
	defer s.deleteMachine(c, m.Id)

	c.Assert(m.Name, gc.Equals, testMachineName)
	c.Assert(m.Package, gc.Equals, testPackage)
	c.Assert(m.Image, gc.Equals, testImage)
	c.Assert(m.Type, gc.Equals, "virtualmachine")
	c.Assert(len(m.IPs), gc.Equals, 2)
	c.Assert(m.State, gc.Equals, "running")
}

func (s *CloudAPIHTTPSuite) TestStartMachine(c *gc.C) {
	var expected cloudapi.Machine
	m := s.createMachine(c, testMachineName, testPackage, testImage, nil, nil)
	defer s.deleteMachine(c, m.Id)

	resp, err := s.sendRequest("POST", fmt.Sprintf("%s?action=start", path.Join(testUserAccount, "machines", m.Id)), nil, nil)
	c.Assert(err, gc.IsNil)
	c.Assert(resp.StatusCode, gc.Equals, http.StatusAccepted)

	s.getMachine(c, m.Id, &expected)
	c.Assert(expected.State, gc.Equals, "running")
}

func (s *CloudAPIHTTPSuite) TestStopMachine(c *gc.C) {
	var expected cloudapi.Machine
	m := s.createMachine(c, testMachineName, testPackage, testImage, nil, nil)
	defer s.deleteMachine(c, m.Id)

	resp, err := s.sendRequest("POST", fmt.Sprintf("%s?action=stop", path.Join(testUserAccount, "machines", m.Id)), nil, nil)
	c.Assert(err, gc.IsNil)
	c.Assert(resp.StatusCode, gc.Equals, http.StatusAccepted)

	s.getMachine(c, m.Id, &expected)
	c.Assert(expected.State, gc.Equals, "stopped")
}

func (s *CloudAPIHTTPSuite) TestRebootMachine(c *gc.C) {
	var expected cloudapi.Machine
	m := s.createMachine(c, testMachineName, testPackage, testImage, nil, nil)
	defer s.deleteMachine(c, m.Id)

	resp, err := s.sendRequest("POST", fmt.Sprintf("%s?action=reboot", path.Join(testUserAccount, "machines", m.Id)), nil, nil)
	c.Assert(err, gc.IsNil)
	c.Assert(resp.StatusCode, gc.Equals, http.StatusAccepted)

	s.getMachine(c, m.Id, &expected)
	c.Assert(expected.State, gc.Equals, "running")
}

func (s *CloudAPIHTTPSuite) TestResizeMachine(c *gc.C) {
	var expected cloudapi.Machine
	m := s.createMachine(c, testMachineName, testPackage, testImage, nil, nil)
	defer s.deleteMachine(c, m.Id)

	resp, err := s.sendRequest("POST", fmt.Sprintf("%s?action=resize&package=Medium", path.Join(testUserAccount, "machines", m.Id)), nil, nil)
	c.Assert(err, gc.IsNil)
	c.Assert(resp.StatusCode, gc.Equals, http.StatusAccepted)

	s.getMachine(c, m.Id, &expected)
	c.Assert(expected.Package, gc.Equals, "Medium")
	c.Assert(expected.Memory, gc.Equals, 2048)
	c.Assert(expected.Disk, gc.Equals, 32768)
}

func (s *CloudAPIHTTPSuite) TestRenameMachine(c *gc.C) {
	var expected cloudapi.Machine
	m := s.createMachine(c, testMachineName, testPackage, testImage, nil, nil)
	defer s.deleteMachine(c, m.Id)

	resp, err := s.sendRequest("POST", fmt.Sprintf("%s?action=rename&name=new-test-name", path.Join(testUserAccount, "machines", m.Id)), nil, nil)
	c.Assert(err, gc.IsNil)
	c.Assert(resp.StatusCode, gc.Equals, http.StatusAccepted)

	s.getMachine(c, m.Id, &expected)
	c.Assert(expected.Name, gc.Equals, "new-test-name")
}

func (s *CloudAPIHTTPSuite) TestListMachinesFirewallRules(c *gc.C) {
	var expected []cloudapi.FirewallRule
	m := s.createMachine(c, testMachineName, testPackage, testImage, nil, nil)
	defer s.deleteMachine(c, m.Id)

	resp, err := s.sendRequest("GET", path.Join(testUserAccount, "machines", m.Id, "fwrules"), nil, nil)
	c.Assert(err, gc.IsNil)
	c.Assert(resp.StatusCode, gc.Equals, http.StatusOK)
	assertJSON(c, resp, &expected)
}

func (s *CloudAPIHTTPSuite) TestEnableFirewallMachine(c *gc.C) {
	m := s.createMachine(c, testMachineName, testPackage, testImage, nil, nil)
	defer s.deleteMachine(c, m.Id)

	resp, err := s.sendRequest("POST", fmt.Sprintf("%s?action=enable_firewall", path.Join(testUserAccount, "machines", m.Id)), nil, nil)
	c.Assert(err, gc.IsNil)
	c.Assert(resp.StatusCode, gc.Equals, http.StatusAccepted)
}

func (s *CloudAPIHTTPSuite) TestDisableFirewallMachine(c *gc.C) {
	m := s.createMachine(c, testMachineName, testPackage, testImage, nil, nil)
	defer s.deleteMachine(c, m.Id)

	resp, err := s.sendRequest("POST", fmt.Sprintf("%s?action=disable_firewall", path.Join(testUserAccount, "machines", m.Id)), nil, nil)
	c.Assert(err, gc.IsNil)
	c.Assert(resp.StatusCode, gc.Equals, http.StatusAccepted)
}

func (s *CloudAPIHTTPSuite) TestDeleteMachine(c *gc.C) {
	m := s.createMachine(c, testMachineName, testPackage, testImage, nil, nil)
	s.deleteMachine(c, m.Id)
}

// Tests for FirewallRules API
func (s *CloudAPIHTTPSuite) TestCreateFirewallRule(c *gc.C) {
	testFwRule := s.createFirewallRule(c)

	// cleanup
	s.deleteFwRule(c, testFwRule.Id)
}

func (s *CloudAPIHTTPSuite) TestListFirewallRules(c *gc.C) {
	var expected []cloudapi.FirewallRule
	testFwRule := s.createFirewallRule(c)
	defer s.deleteFwRule(c, testFwRule.Id)

	resp, err := s.sendRequest("GET", path.Join(testUserAccount, "fwrules"), nil, nil)
	c.Assert(err, gc.IsNil)
	c.Assert(resp.StatusCode, gc.Equals, http.StatusOK)
	assertJSON(c, resp, &expected)
}

func (s *CloudAPIHTTPSuite) TestGetFirewallRule(c *gc.C) {
	var expected cloudapi.FirewallRule
	testFwRule := s.createFirewallRule(c)
	defer s.deleteFwRule(c, testFwRule.Id)

	resp, err := s.sendRequest("GET", path.Join(testUserAccount, "fwrules", testFwRule.Id), nil, nil)
	c.Assert(err, gc.IsNil)
	c.Assert(resp.StatusCode, gc.Equals, http.StatusOK)
	assertJSON(c, resp, &expected)
}

func (s *CloudAPIHTTPSuite) TestUpdateFirewallRule(c *gc.C) {
	var expected cloudapi.FirewallRule
	testFwRule := s.createFirewallRule(c)
	defer s.deleteFwRule(c, testFwRule.Id)

	opts := cloudapi.CreateFwRuleOpts{Rule: testUpdatedFwRule, Enabled: true}
	optsByte, err := json.Marshal(opts)
	c.Assert(err, gc.IsNil)
	resp, err := s.sendRequest("POST", path.Join(testUserAccount, "fwrules", testFwRule.Id), optsByte, nil)
	c.Assert(err, gc.IsNil)
	c.Assert(resp.StatusCode, gc.Equals, http.StatusOK)
	assertJSON(c, resp, &expected)
	c.Assert(expected.Rule, gc.Equals, testUpdatedFwRule)
}

func (s *CloudAPIHTTPSuite) TestEnableFirewallRule(c *gc.C) {
	var expected cloudapi.FirewallRule
	testFwRule := s.createFirewallRule(c)
	defer s.deleteFwRule(c, testFwRule.Id)

	resp, err := s.sendRequest("POST", path.Join(testUserAccount, "fwrules", testFwRule.Id, "enable"), nil, nil)
	c.Assert(err, gc.IsNil)
	c.Assert(resp.StatusCode, gc.Equals, http.StatusOK)
	assertJSON(c, resp, &expected)
	c.Assert(expected.Enabled, gc.Equals, true)
}

func (s *CloudAPIHTTPSuite) TestDisableFirewallRule(c *gc.C) {
	var expected cloudapi.FirewallRule
	testFwRule := s.createFirewallRule(c)
	defer s.deleteFwRule(c, testFwRule.Id)

	resp, err := s.sendRequest("POST", path.Join(testUserAccount, "fwrules", testFwRule.Id, "disable"), nil, nil)
	c.Assert(err, gc.IsNil)
	c.Assert(resp.StatusCode, gc.Equals, http.StatusOK)
	assertJSON(c, resp, &expected)
	c.Assert(expected.Enabled, gc.Equals, false)
}

func (s *CloudAPIHTTPSuite) TestDeleteFirewallRule(c *gc.C) {
	testFwRule := s.createFirewallRule(c)

	s.deleteFwRule(c, testFwRule.Id)
}

// tests for Networks API
func (s *CloudAPIHTTPSuite) TestListNetworks(c *gc.C) {
	var expected []cloudapi.Network

	resp, err := s.sendRequest("GET", path.Join(testUserAccount, "networks"), nil, nil)
	c.Assert(err, gc.IsNil)
	c.Assert(resp.StatusCode, gc.Equals, http.StatusOK)
	assertJSON(c, resp, &expected)
}

func (s *CloudAPIHTTPSuite) TestGetNetwork(c *gc.C) {
	var expected cloudapi.Network

	resp, err := s.sendRequest("GET", path.Join(testUserAccount, "networks", testNetworkID), nil, nil)
	c.Assert(err, gc.IsNil)
	c.Assert(resp.StatusCode, gc.Equals, http.StatusOK)
	assertJSON(c, resp, &expected)
	c.Assert(expected, gc.DeepEquals, cloudapi.Network{
		Id:          testNetworkID,
		Name:        "Test-Joyent-Public",
		Public:      true,
		Description: "",
	})
}

func (s *CloudAPIHTTPSuite) TestGetServices(c *gc.C) {
	//var expected cloudapi.ServiceInstance
	resp, err := s.sendRequest("GET", path.Join(testUserAccount, "services"), nil, nil)
	c.Assert(err, gc.IsNil)
	c.Assert(resp.StatusCode, gc.Equals, http.StatusOK)

}
