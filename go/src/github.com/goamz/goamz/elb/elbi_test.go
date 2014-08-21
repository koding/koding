package elb_test

import (
	"flag"
	"github.com/goamz/goamz/aws"
	"github.com/goamz/goamz/ec2"
	"github.com/goamz/goamz/elb"
	"github.com/motain/gocheck"
)

var amazon = flag.Bool("amazon", false, "Enable tests against amazon server")

// AmazonServer represents an Amazon AWS server.
type AmazonServer struct {
	auth aws.Auth
}

func (s *AmazonServer) SetUp(c *gocheck.C) {
	auth, err := aws.EnvAuth()
	if err != nil {
		c.Fatal(err)
	}
	s.auth = auth
}

var _ = gocheck.Suite(&AmazonClientSuite{})

// AmazonClientSuite tests the client against a live AWS server.
type AmazonClientSuite struct {
	srv AmazonServer
	ClientTests
}

// ClientTests defines integration tests designed to test the client.
// It is not used as a test suite in itself, but embedded within
// another type.
type ClientTests struct {
	elb *elb.ELB
	ec2 *ec2.EC2
}

func (s *AmazonClientSuite) SetUpSuite(c *gocheck.C) {
	if !*amazon {
		c.Skip("AmazonClientSuite tests not enabled")
	}
	s.srv.SetUp(c)
	s.elb = elb.New(s.srv.auth, aws.USEast)
	s.ec2 = ec2.New(s.srv.auth, aws.USEast)
}

func (s *ClientTests) TestCreateAndDeleteLoadBalancer(c *gocheck.C) {
	createLBReq := elb.CreateLoadBalancer{
		Name:              "testlb",
		AvailabilityZones: []string{"us-east-1a"},
		Listeners: []elb.Listener{
			{
				InstancePort:     80,
				InstanceProtocol: "http",
				LoadBalancerPort: 80,
				Protocol:         "http",
			},
		},
	}
	resp, err := s.elb.CreateLoadBalancer(&createLBReq)
	c.Assert(err, gocheck.IsNil)
	defer s.elb.DeleteLoadBalancer(createLBReq.Name)
	c.Assert(resp.DNSName, gocheck.Not(gocheck.Equals), "")
	deleteResp, err := s.elb.DeleteLoadBalancer(createLBReq.Name)
	c.Assert(err, gocheck.IsNil)
	c.Assert(deleteResp.RequestId, gocheck.Not(gocheck.Equals), "")
}

func (s *ClientTests) TestCreateLoadBalancerError(c *gocheck.C) {
	createLBReq := elb.CreateLoadBalancer{
		Name:              "testlb",
		AvailabilityZones: []string{"us-east-1a"},
		Subnets:           []string{"subnetid-1"},
		Listeners: []elb.Listener{
			{
				InstancePort:     80,
				InstanceProtocol: "http",
				LoadBalancerPort: 80,
				Protocol:         "http",
			},
		},
	}
	resp, err := s.elb.CreateLoadBalancer(&createLBReq)
	c.Assert(resp, gocheck.IsNil)
	c.Assert(err, gocheck.NotNil)
	e, ok := err.(*elb.Error)
	c.Assert(ok, gocheck.Equals, true)
	c.Assert(e.Message, gocheck.Matches, "Only one of .* or .* may be specified")
	c.Assert(e.Code, gocheck.Equals, "ValidationError")
}

func (s *ClientTests) createInstanceAndLB(c *gocheck.C) (*elb.CreateLoadBalancer, string) {
	options := ec2.RunInstancesOptions{
		ImageId:          "ami-ccf405a5",
		InstanceType:     "t1.micro",
		AvailabilityZone: "us-east-1c",
	}
	resp1, err := s.ec2.RunInstances(&options)
	c.Assert(err, gocheck.IsNil)
	instId := resp1.Instances[0].InstanceId
	createLBReq := elb.CreateLoadBalancer{
		Name:              "testlb",
		AvailabilityZones: []string{"us-east-1c"},
		Listeners: []elb.Listener{
			{
				InstancePort:     80,
				InstanceProtocol: "http",
				LoadBalancerPort: 80,
				Protocol:         "http",
			},
		},
	}
	_, err = s.elb.CreateLoadBalancer(&createLBReq)
	c.Assert(err, gocheck.IsNil)
	return &createLBReq, instId
}

// Cost: 0.02 USD
func (s *ClientTests) TestCreateRegisterAndDeregisterInstanceWithLoadBalancer(c *gocheck.C) {
	createLBReq, instId := s.createInstanceAndLB(c)
	defer func() {
		_, err := s.elb.DeleteLoadBalancer(createLBReq.Name)
		c.Check(err, gocheck.IsNil)
		_, err = s.ec2.TerminateInstances([]string{instId})
		c.Check(err, gocheck.IsNil)
	}()
	resp, err := s.elb.RegisterInstancesWithLoadBalancer([]string{instId}, createLBReq.Name)
	c.Assert(err, gocheck.IsNil)
	c.Assert(resp.InstanceIds, gocheck.DeepEquals, []string{instId})
	resp2, err := s.elb.DeregisterInstancesFromLoadBalancer([]string{instId}, createLBReq.Name)
	c.Assert(err, gocheck.IsNil)
	c.Assert(resp2, gocheck.Not(gocheck.Equals), "")
}

func (s *ClientTests) TestDescribeLoadBalancers(c *gocheck.C) {
	createLBReq := elb.CreateLoadBalancer{
		Name:              "testlb",
		AvailabilityZones: []string{"us-east-1a"},
		Listeners: []elb.Listener{
			{
				InstancePort:     80,
				InstanceProtocol: "http",
				LoadBalancerPort: 80,
				Protocol:         "http",
			},
		},
	}
	_, err := s.elb.CreateLoadBalancer(&createLBReq)
	c.Assert(err, gocheck.IsNil)
	defer func() {
		_, err := s.elb.DeleteLoadBalancer(createLBReq.Name)
		c.Check(err, gocheck.IsNil)
	}()
	resp, err := s.elb.DescribeLoadBalancers()
	c.Assert(err, gocheck.IsNil)
	c.Assert(len(resp.LoadBalancerDescriptions) > 0, gocheck.Equals, true)
	c.Assert(resp.LoadBalancerDescriptions[0].AvailabilityZones, gocheck.DeepEquals, []string{"us-east-1a"})
	c.Assert(resp.LoadBalancerDescriptions[0].LoadBalancerName, gocheck.Equals, "testlb")
	c.Assert(resp.LoadBalancerDescriptions[0].Scheme, gocheck.Equals, "internet-facing")
	hc := elb.HealthCheck{
		HealthyThreshold:   10,
		Interval:           30,
		Target:             "TCP:80",
		Timeout:            5,
		UnhealthyThreshold: 2,
	}
	c.Assert(resp.LoadBalancerDescriptions[0].HealthCheck, gocheck.DeepEquals, hc)
	ld := []elb.ListenerDescription{
		{
			Listener: elb.Listener{
				Protocol:         "HTTP",
				LoadBalancerPort: 80,
				InstanceProtocol: "HTTP",
				InstancePort:     80,
			},
		},
	}
	c.Assert(resp.LoadBalancerDescriptions[0].ListenerDescriptions, gocheck.DeepEquals, ld)
	ssg := elb.SourceSecurityGroup{
		GroupName:  "amazon-elb-sg",
		OwnerAlias: "amazon-elb",
	}
	c.Assert(resp.LoadBalancerDescriptions[0].SourceSecurityGroup, gocheck.DeepEquals, ssg)
}

func (s *ClientTests) TestDescribeLoadBalancersBadRequest(c *gocheck.C) {
	resp, err := s.elb.DescribeLoadBalancers("absentlb")
	c.Assert(err, gocheck.NotNil)
	c.Assert(resp, gocheck.IsNil)
	c.Assert(err, gocheck.ErrorMatches, ".*(LoadBalancerNotFound).*")
}

func (s *ClientTests) TestDescribeInstanceHealth(c *gocheck.C) {
	createLBReq, instId := s.createInstanceAndLB(c)
	defer func() {
		_, err := s.elb.DeleteLoadBalancer(createLBReq.Name)
		c.Check(err, gocheck.IsNil)
		_, err = s.ec2.TerminateInstances([]string{instId})
		c.Check(err, gocheck.IsNil)
	}()
	_, err := s.elb.RegisterInstancesWithLoadBalancer([]string{instId}, createLBReq.Name)
	c.Assert(err, gocheck.IsNil)
	resp, err := s.elb.DescribeInstanceHealth(createLBReq.Name, instId)
	c.Assert(err, gocheck.IsNil)
	c.Assert(len(resp.InstanceStates) > 0, gocheck.Equals, true)
	c.Assert(resp.InstanceStates[0].Description, gocheck.Equals, "Instance is in pending state.")
	c.Assert(resp.InstanceStates[0].InstanceId, gocheck.Equals, instId)
	c.Assert(resp.InstanceStates[0].State, gocheck.Equals, "OutOfService")
	c.Assert(resp.InstanceStates[0].ReasonCode, gocheck.Equals, "Instance")
}

func (s *ClientTests) TestDescribeInstanceHealthBadRequest(c *gocheck.C) {
	createLBReq := elb.CreateLoadBalancer{
		Name:              "testlb",
		AvailabilityZones: []string{"us-east-1a"},
		Listeners: []elb.Listener{
			{
				InstancePort:     80,
				InstanceProtocol: "http",
				LoadBalancerPort: 80,
				Protocol:         "http",
			},
		},
	}
	_, err := s.elb.CreateLoadBalancer(&createLBReq)
	c.Assert(err, gocheck.IsNil)
	defer func() {
		_, err := s.elb.DeleteLoadBalancer(createLBReq.Name)
		c.Check(err, gocheck.IsNil)
	}()
	resp, err := s.elb.DescribeInstanceHealth(createLBReq.Name, "i-foo")
	c.Assert(resp, gocheck.IsNil)
	c.Assert(err, gocheck.NotNil)
	c.Assert(err, gocheck.ErrorMatches, ".*i-foo.*(InvalidInstance).*")
}

func (s *ClientTests) TestConfigureHealthCheck(c *gocheck.C) {
	createLBReq := elb.CreateLoadBalancer{
		Name:              "testlb",
		AvailabilityZones: []string{"us-east-1a"},
		Listeners: []elb.Listener{
			{
				InstancePort:     80,
				InstanceProtocol: "http",
				LoadBalancerPort: 80,
				Protocol:         "http",
			},
		},
	}
	_, err := s.elb.CreateLoadBalancer(&createLBReq)
	c.Assert(err, gocheck.IsNil)
	defer func() {
		_, err := s.elb.DeleteLoadBalancer(createLBReq.Name)
		c.Check(err, gocheck.IsNil)
	}()
	hc := elb.HealthCheck{
		HealthyThreshold:   10,
		Interval:           30,
		Target:             "HTTP:80/",
		Timeout:            5,
		UnhealthyThreshold: 2,
	}
	resp, err := s.elb.ConfigureHealthCheck(createLBReq.Name, &hc)
	c.Assert(err, gocheck.IsNil)
	c.Assert(resp.HealthCheck.HealthyThreshold, gocheck.Equals, 10)
	c.Assert(resp.HealthCheck.Interval, gocheck.Equals, 30)
	c.Assert(resp.HealthCheck.Target, gocheck.Equals, "HTTP:80/")
	c.Assert(resp.HealthCheck.Timeout, gocheck.Equals, 5)
	c.Assert(resp.HealthCheck.UnhealthyThreshold, gocheck.Equals, 2)
}

func (s *ClientTests) TestConfigureHealthCheckBadRequest(c *gocheck.C) {
	createLBReq := elb.CreateLoadBalancer{
		Name:              "testlb",
		AvailabilityZones: []string{"us-east-1a"},
		Listeners: []elb.Listener{
			{
				InstancePort:     80,
				InstanceProtocol: "http",
				LoadBalancerPort: 80,
				Protocol:         "http",
			},
		},
	}
	_, err := s.elb.CreateLoadBalancer(&createLBReq)
	c.Assert(err, gocheck.IsNil)
	defer func() {
		_, err := s.elb.DeleteLoadBalancer(createLBReq.Name)
		c.Check(err, gocheck.IsNil)
	}()
	hc := elb.HealthCheck{
		HealthyThreshold:   10,
		Interval:           30,
		Target:             "HTTP:80",
		Timeout:            5,
		UnhealthyThreshold: 2,
	}
	resp, err := s.elb.ConfigureHealthCheck(createLBReq.Name, &hc)
	c.Assert(resp, gocheck.IsNil)
	c.Assert(err, gocheck.NotNil)
	expected := "HealthCheck HTTP Target must specify a port followed by a path that begins with a slash. e.g. HTTP:80/ping/this/path (ValidationError)"
	c.Assert(err.Error(), gocheck.Equals, expected)
}
