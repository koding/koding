package elb_test

import (
	"github.com/mitchellh/goamz/aws"
	"github.com/mitchellh/goamz/elb"
	"github.com/mitchellh/goamz/testutil"
	. "github.com/motain/gocheck"
	"testing"
)

func Test(t *testing.T) {
	TestingT(t)
}

type S struct {
	elb *elb.ELB
}

var _ = Suite(&S{})

var testServer = testutil.NewHTTPServer()

func (s *S) SetUpSuite(c *C) {
	testServer.Start()
	auth := aws.Auth{"abc", "123", ""}
	s.elb = elb.NewWithClient(auth, aws.Region{ELBEndpoint: testServer.URL}, testutil.DefaultClient)
}

func (s *S) TearDownTest(c *C) {
	testServer.Flush()
}

func (s *S) TestCreateLoadBalancer(c *C) {
	testServer.Response(200, nil, CreateLoadBalancerExample)

	options := elb.CreateLoadBalancer{
		AvailZone: []string{"us-east-1a"},
		Listeners: []elb.Listener{elb.Listener{
			InstancePort:     80,
			InstanceProtocol: "http",
			LoadBalancerPort: 80,
			Protocol:         "http",
		},
		},
		LoadBalancerName: "foobar",
		Internal:         false,
		SecurityGroups:   []string{"sg1"},
		Subnets:          []string{"sn1"},
	}

	resp, err := s.elb.CreateLoadBalancer(&options)
	req := testServer.WaitRequest()

	c.Assert(req.Form["Action"], DeepEquals, []string{"CreateLoadBalancer"})
	c.Assert(req.Form["LoadBalancerName"], DeepEquals, []string{"foobar"})
	c.Assert(err, IsNil)
	c.Assert(resp.RequestId, Equals, "1549581b-12b7-11e3-895e-1334aEXAMPLE")
}

func (s *S) TestDeleteLoadBalancer(c *C) {
	testServer.Response(200, nil, DeleteLoadBalancerExample)

	options := elb.DeleteLoadBalancer{
		LoadBalancerName: "foobar",
	}

	resp, err := s.elb.DeleteLoadBalancer(&options)
	req := testServer.WaitRequest()

	c.Assert(req.Form["Action"], DeepEquals, []string{"DeleteLoadBalancer"})
	c.Assert(req.Form["LoadBalancerName"], DeepEquals, []string{"foobar"})
	c.Assert(err, IsNil)
	c.Assert(resp.RequestId, Equals, "1549581b-12b7-11e3-895e-1334aEXAMPLE")
}

func (s *S) TestDescribeLoadBalancers(c *C) {
	testServer.Response(200, nil, DescribeLoadBalancersExample)

	options := elb.DescribeLoadBalancer{
		Names: []string{"foobar"},
	}

	resp, err := s.elb.DescribeLoadBalancers(&options)
	req := testServer.WaitRequest()

	c.Assert(req.Form["Action"], DeepEquals, []string{"DescribeLoadBalancers"})
	c.Assert(err, IsNil)
	c.Assert(resp.RequestId, Equals, "83c88b9d-12b7-11e3-8b82-87b12EXAMPLE")
	c.Assert(resp.LoadBalancers[0].LoadBalancerName, Equals, "MyLoadBalancer")
	c.Assert(resp.LoadBalancers[0].Listeners[0].Protocol, Equals, "HTTP")
	c.Assert(resp.LoadBalancers[0].Instances[0].InstanceId, Equals, "i-e4cbe38d")
	c.Assert(resp.LoadBalancers[0].AvailabilityZones[0].AvailabilityZone, Equals, "us-east-1a")
	c.Assert(resp.LoadBalancers[0].Scheme, Equals, "internet-facing")
	c.Assert(resp.LoadBalancers[0].DNSName, Equals, "MyLoadBalancer-123456789.us-east-1.elb.amazonaws.com")
}

func (s *S) TestRegisterInstancesWithLoadBalancer(c *C) {
	testServer.Response(200, nil, RegisterInstancesWithLoadBalancerExample)

	options := elb.RegisterInstancesWithLoadBalancer{
		LoadBalancerName: "foobar",
		Instances:        []string{"instance-1", "instance-2"},
	}

	resp, err := s.elb.RegisterInstancesWithLoadBalancer(&options)
	req := testServer.WaitRequest()

	c.Assert(req.Form["Action"], DeepEquals, []string{"RegisterInstancesWithLoadBalancer"})
	c.Assert(req.Form["LoadBalancerName"], DeepEquals, []string{"foobar"})
	c.Assert(req.Form["Instances.member.1.InstanceId"], DeepEquals, []string{"instance-1"})
	c.Assert(req.Form["Instances.member.2.InstanceId"], DeepEquals, []string{"instance-2"})
	c.Assert(err, IsNil)

	c.Assert(resp.Instances[0].InstanceId, Equals, "i-315b7e51")
	c.Assert(resp.RequestId, Equals, "83c88b9d-12b7-11e3-8b82-87b12EXAMPLE")
}

func (s *S) TestDeregisterInstancesFromLoadBalancer(c *C) {
	testServer.Response(200, nil, DeregisterInstancesFromLoadBalancerExample)

	options := elb.DeregisterInstancesFromLoadBalancer{
		LoadBalancerName: "foobar",
		Instances:        []string{"instance-1", "instance-2"},
	}

	resp, err := s.elb.DeregisterInstancesFromLoadBalancer(&options)
	req := testServer.WaitRequest()

	c.Assert(req.Form["Action"], DeepEquals, []string{"DeregisterInstancesFromLoadBalancer"})
	c.Assert(req.Form["LoadBalancerName"], DeepEquals, []string{"foobar"})
	c.Assert(req.Form["Instances.member.1.InstanceId"], DeepEquals, []string{"instance-1"})
	c.Assert(req.Form["Instances.member.2.InstanceId"], DeepEquals, []string{"instance-2"})
	c.Assert(err, IsNil)

	c.Assert(resp.Instances[0].InstanceId, Equals, "i-6ec63d59")
	c.Assert(resp.RequestId, Equals, "83c88b9d-12b7-11e3-8b82-87b12EXAMPLE")
}

func (s *S) TestDescribeInstanceHealth(c *C) {
	testServer.Response(200, nil, DescribeInstanceHealthExample)

	options := elb.DescribeInstanceHealth{
		LoadBalancerName: "foobar",
	}

	resp, err := s.elb.DescribeInstanceHealth(&options)
	req := testServer.WaitRequest()

	c.Assert(req.Form["Action"], DeepEquals, []string{"DescribeInstanceHealth"})
	c.Assert(req.Form["LoadBalancerName"], DeepEquals, []string{"foobar"})
	c.Assert(err, IsNil)

	c.Assert(resp.InstanceStates[0].InstanceId, Equals, "i-90d8c2a5")
	c.Assert(resp.InstanceStates[0].State, Equals, "InService")
	c.Assert(resp.RequestId, Equals, "1549581b-12b7-11e3-895e-1334aEXAMPLE")
}
