package elb_test

import (
	"github.com/goamz/goamz/aws"
	"github.com/goamz/goamz/elb"
	"github.com/goamz/goamz/elb/elbtest"
	"github.com/motain/gocheck"
)

// LocalServer represents a local elbtest fake server.
type LocalServer struct {
	auth   aws.Auth
	region aws.Region
	srv    *elbtest.Server
}

func (s *LocalServer) SetUp(c *gocheck.C) {
	srv, err := elbtest.NewServer()
	c.Assert(err, gocheck.IsNil)
	c.Assert(srv, gocheck.NotNil)
	s.srv = srv
	s.region = aws.Region{ELBEndpoint: srv.URL()}
}

// LocalServerSuite defines tests that will run
// against the local elbtest server. It includes
// selected tests from ClientTests;
// when the elbtest functionality is sufficient, it should
// include all of them, and ClientTests can be simply embedded.
type LocalServerSuite struct {
	srv LocalServer
	ServerTests
	clientTests ClientTests
}

// ServerTests defines a set of tests designed to test
// the elbtest local fake elb server.
// It is not used as a test suite in itself, but embedded within
// another type.
type ServerTests struct {
	elb *elb.ELB
}

// AmazonServerSuite runs the elbtest server tests against a live ELB server.
// It will only be activated if the -all flag is specified.
type AmazonServerSuite struct {
	srv AmazonServer
	ServerTests
}

var _ = gocheck.Suite(&AmazonServerSuite{})

func (s *AmazonServerSuite) SetUpSuite(c *gocheck.C) {
	if !*amazon {
		c.Skip("AmazonServerSuite tests not enabled")
	}
	s.srv.SetUp(c)
	s.ServerTests.elb = elb.New(s.srv.auth, aws.USEast)
}

var _ = gocheck.Suite(&LocalServerSuite{})

func (s *LocalServerSuite) SetUpSuite(c *gocheck.C) {
	s.srv.SetUp(c)
	s.ServerTests.elb = elb.New(s.srv.auth, s.srv.region)
	s.clientTests.elb = elb.New(s.srv.auth, s.srv.region)
}

func (s *LocalServerSuite) TestCreateLoadBalancer(c *gocheck.C) {
	s.clientTests.TestCreateAndDeleteLoadBalancer(c)
}

func (s *LocalServerSuite) TestCreateLoadBalancerError(c *gocheck.C) {
	s.clientTests.TestCreateLoadBalancerError(c)
}

func (s *LocalServerSuite) TestDescribeLoadBalancer(c *gocheck.C) {
	s.clientTests.TestDescribeLoadBalancers(c)
}

func (s *LocalServerSuite) TestDescribeLoadBalancerListsAddedByNewLoadbalancerFunc(c *gocheck.C) {
	srv := s.srv.srv
	srv.NewLoadBalancer("wierdlb")
	defer srv.RemoveLoadBalancer("wierdlb")
	resp, err := s.clientTests.elb.DescribeLoadBalancers()
	c.Assert(err, gocheck.IsNil)
	isPresent := false
	for _, desc := range resp.LoadBalancerDescriptions {
		if desc.LoadBalancerName == "wierdlb" {
			isPresent = true
		}
	}
	c.Assert(isPresent, gocheck.Equals, true)
}

func (s *LocalServerSuite) TestDescribeLoadBalancerListsInstancesAddedByRegisterInstancesFunc(c *gocheck.C) {
	srv := s.srv.srv
	lbName := "somelb"
	srv.NewLoadBalancer(lbName)
	defer srv.RemoveLoadBalancer(lbName)
	instId := srv.NewInstance()
	defer srv.RemoveInstance(instId)
	srv.RegisterInstance(instId, lbName) // no need to deregister, since we're removing the lb
	resp, err := s.clientTests.elb.DescribeLoadBalancers()
	c.Assert(err, gocheck.IsNil)
	c.Assert(len(resp.LoadBalancerDescriptions) > 0, gocheck.Equals, true)
	c.Assert(len(resp.LoadBalancerDescriptions[0].Instances) > 0, gocheck.Equals, true)
	c.Assert(resp.LoadBalancerDescriptions[0].Instances, gocheck.DeepEquals, []elb.Instance{{InstanceId: instId}})
	srv.DeregisterInstance(instId, lbName)
	resp, err = s.clientTests.elb.DescribeLoadBalancers()
	c.Assert(err, gocheck.IsNil)
	c.Assert(resp.LoadBalancerDescriptions[0].Instances, gocheck.DeepEquals, []elb.Instance(nil))
}

func (s *LocalServerSuite) TestDescribeLoadBalancersBadRequest(c *gocheck.C) {
	s.clientTests.TestDescribeLoadBalancersBadRequest(c)
}

func (s *LocalServerSuite) TestRegisterInstanceWithLoadBalancer(c *gocheck.C) {
	srv := s.srv.srv
	instId := srv.NewInstance()
	defer srv.RemoveInstance(instId)
	srv.NewLoadBalancer("testlb")
	defer srv.RemoveLoadBalancer("testlb")
	resp, err := s.clientTests.elb.RegisterInstancesWithLoadBalancer([]string{instId}, "testlb")
	c.Assert(err, gocheck.IsNil)
	c.Assert(resp.InstanceIds, gocheck.DeepEquals, []string{instId})
}

func (s *LocalServerSuite) TestRegisterInstanceWithLoadBalancerWithAbsentInstance(c *gocheck.C) {
	srv := s.srv.srv
	srv.NewLoadBalancer("testlb")
	defer srv.RemoveLoadBalancer("testlb")
	resp, err := s.clientTests.elb.RegisterInstancesWithLoadBalancer([]string{"i-212"}, "testlb")
	c.Assert(err, gocheck.NotNil)
	c.Assert(err, gocheck.ErrorMatches, `^InvalidInstance found in \[i-212\]. Invalid id: "i-212" \(InvalidInstance\)$`)
	c.Assert(resp, gocheck.IsNil)
}

func (s *LocalServerSuite) TestRegisterInstanceWithLoadBalancerWithAbsentLoadBalancer(c *gocheck.C) {
	// the verification if the lb exists is done before the instances, so there is no need to create
	// fixture instances for this test, it'll never get that far
	resp, err := s.clientTests.elb.RegisterInstancesWithLoadBalancer([]string{"i-212"}, "absentlb")
	c.Assert(err, gocheck.NotNil)
	c.Assert(err, gocheck.ErrorMatches, `^There is no ACTIVE Load Balancer named 'absentlb' \(LoadBalancerNotFound\)$`)
	c.Assert(resp, gocheck.IsNil)
}

func (s *LocalServerSuite) TestDeregisterInstanceWithLoadBalancer(c *gocheck.C) {
	// there is no need to register the instance first, amazon returns the same response
	// in both cases (instance registered or not)
	srv := s.srv.srv
	instId := srv.NewInstance()
	defer srv.RemoveInstance(instId)
	srv.NewLoadBalancer("testlb")
	defer srv.RemoveLoadBalancer("testlb")
	resp, err := s.clientTests.elb.DeregisterInstancesFromLoadBalancer([]string{instId}, "testlb")
	c.Assert(err, gocheck.IsNil)
	c.Assert(resp.RequestId, gocheck.Not(gocheck.Equals), "")
}

func (s *LocalServerSuite) TestDeregisterInstanceWithLoadBalancerWithAbsentLoadBalancer(c *gocheck.C) {
	resp, err := s.clientTests.elb.DeregisterInstancesFromLoadBalancer([]string{"i-212"}, "absentlb")
	c.Assert(resp, gocheck.IsNil)
	c.Assert(err, gocheck.NotNil)
	c.Assert(err, gocheck.ErrorMatches, `^There is no ACTIVE Load Balancer named 'absentlb' \(LoadBalancerNotFound\)$`)
}

func (s *LocalServerSuite) TestDeregisterInstancewithLoadBalancerWithAbsentInstance(c *gocheck.C) {
	srv := s.srv.srv
	srv.NewLoadBalancer("testlb")
	defer srv.RemoveLoadBalancer("testlb")
	resp, err := s.clientTests.elb.DeregisterInstancesFromLoadBalancer([]string{"i-212"}, "testlb")
	c.Assert(resp, gocheck.IsNil)
	c.Assert(err, gocheck.NotNil)
	c.Assert(err, gocheck.ErrorMatches, `^InvalidInstance found in \[i-212\]. Invalid id: "i-212" \(InvalidInstance\)$`)
}

func (s *LocalServerSuite) TestDescribeInstanceHealth(c *gocheck.C) {
	srv := s.srv.srv
	instId := srv.NewInstance()
	defer srv.RemoveInstance(instId)
	srv.NewLoadBalancer("testlb")
	defer srv.RemoveLoadBalancer("testlb")
	resp, err := s.clientTests.elb.DescribeInstanceHealth("testlb", instId)
	c.Assert(err, gocheck.IsNil)
	c.Assert(len(resp.InstanceStates) > 0, gocheck.Equals, true)
	c.Assert(resp.InstanceStates[0].Description, gocheck.Equals, "Instance is in pending state.")
	c.Assert(resp.InstanceStates[0].InstanceId, gocheck.Equals, instId)
	c.Assert(resp.InstanceStates[0].State, gocheck.Equals, "OutOfService")
	c.Assert(resp.InstanceStates[0].ReasonCode, gocheck.Equals, "Instance")
}

func (s *LocalServerSuite) TestDescribeInstanceHealthBadRequest(c *gocheck.C) {
	s.clientTests.TestDescribeInstanceHealthBadRequest(c)
}

func (s *LocalServerSuite) TestDescribeInstanceHealthWithoutSpecifyingInstances(c *gocheck.C) {
	srv := s.srv.srv
	instId := srv.NewInstance()
	defer srv.RemoveInstance(instId)
	srv.NewLoadBalancer("testlb")
	defer srv.RemoveLoadBalancer("testlb")
	srv.RegisterInstance(instId, "testlb")
	resp, err := s.clientTests.elb.DescribeInstanceHealth("testlb")
	c.Assert(err, gocheck.IsNil)
	c.Assert(len(resp.InstanceStates) > 0, gocheck.Equals, true)
	c.Assert(resp.InstanceStates[0].Description, gocheck.Equals, "Instance is in pending state.")
	c.Assert(resp.InstanceStates[0].InstanceId, gocheck.Equals, instId)
	c.Assert(resp.InstanceStates[0].State, gocheck.Equals, "OutOfService")
	c.Assert(resp.InstanceStates[0].ReasonCode, gocheck.Equals, "Instance")
}

func (s *LocalServerSuite) TestDescribeInstanceHealthChangingIt(c *gocheck.C) {
	srv := s.srv.srv
	instId := srv.NewInstance()
	defer srv.RemoveInstance(instId)
	srv.NewLoadBalancer("somelb")
	defer srv.RemoveLoadBalancer("somelb")
	srv.RegisterInstance(instId, "somelb")
	state := elb.InstanceState{
		Description: "Instance has failed at least the UnhealthyThreshold number of health checks consecutively",
		InstanceId:  instId,
		State:       "OutOfService",
		ReasonCode:  "Instance",
	}
	srv.ChangeInstanceState("somelb", state)
	resp, err := s.clientTests.elb.DescribeInstanceHealth("somelb")
	c.Assert(err, gocheck.IsNil)
	c.Assert(len(resp.InstanceStates) > 0, gocheck.Equals, true)
	c.Assert(resp.InstanceStates[0].Description, gocheck.Equals, "Instance has failed at least the UnhealthyThreshold number of health checks consecutively")
	c.Assert(resp.InstanceStates[0].InstanceId, gocheck.Equals, instId)
	c.Assert(resp.InstanceStates[0].State, gocheck.Equals, "OutOfService")
	c.Assert(resp.InstanceStates[0].ReasonCode, gocheck.Equals, "Instance")
}

func (s *LocalServerSuite) TestConfigureHealthCheck(c *gocheck.C) {
	s.clientTests.TestConfigureHealthCheck(c)
}

func (s *LocalServerSuite) TestConfigureHealthCheckBadRequest(c *gocheck.C) {
	s.clientTests.TestConfigureHealthCheckBadRequest(c)
}
