package elb_test

import (
	"github.com/goamz/goamz/aws"
	"github.com/goamz/goamz/elb"
	"github.com/motain/gocheck"
	"time"
)

type S struct {
	HTTPSuite
	elb *elb.ELB
}

var _ = gocheck.Suite(&S{})

func (s *S) SetUpSuite(c *gocheck.C) {
	s.HTTPSuite.SetUpSuite(c)
	auth := aws.Auth{AccessKey: "abc", SecretKey: "123"}
	s.elb = elb.New(auth, aws.Region{ELBEndpoint: testServer.URL})
}

func (s *S) TestCreateLoadBalancer(c *gocheck.C) {
	testServer.PrepareResponse(200, nil, CreateLoadBalancer)
	createLB := &elb.CreateLoadBalancer{
		Name:              "testlb",
		AvailabilityZones: []string{"us-east-1a", "us-east-1b"},
		Listeners: []elb.Listener{
			{
				InstancePort:     80,
				InstanceProtocol: "http",
				Protocol:         "http",
				LoadBalancerPort: 80,
			},
		},
	}
	resp, err := s.elb.CreateLoadBalancer(createLB)
	c.Assert(err, gocheck.IsNil)
	defer s.elb.DeleteLoadBalancer(createLB.Name)
	values := testServer.WaitRequest().URL.Query()
	c.Assert(values.Get("Version"), gocheck.Equals, "2012-06-01")
	c.Assert(values.Get("Action"), gocheck.Equals, "CreateLoadBalancer")
	c.Assert(values.Get("Timestamp"), gocheck.Not(gocheck.Equals), "")
	c.Assert(values.Get("LoadBalancerName"), gocheck.Equals, "testlb")
	c.Assert(values.Get("AvailabilityZones.member.1"), gocheck.Equals, "us-east-1a")
	c.Assert(values.Get("AvailabilityZones.member.2"), gocheck.Equals, "us-east-1b")
	c.Assert(values.Get("Listeners.member.1.InstancePort"), gocheck.Equals, "80")
	c.Assert(values.Get("Listeners.member.1.InstanceProtocol"), gocheck.Equals, "http")
	c.Assert(values.Get("Listeners.member.1.Protocol"), gocheck.Equals, "http")
	c.Assert(values.Get("Listeners.member.1.LoadBalancerPort"), gocheck.Equals, "80")
	c.Assert(values.Get("Signature"), gocheck.Not(gocheck.Equals), "")
	c.Assert(resp.DNSName, gocheck.Equals, "testlb-339187009.us-east-1.elb.amazonaws.com")
}

func (s *S) TestCreateLoadBalancerWithSubnetsAndMoreListeners(c *gocheck.C) {
	testServer.PrepareResponse(200, nil, CreateLoadBalancer)
	createLB := &elb.CreateLoadBalancer{
		Name: "testlb",
		Listeners: []elb.Listener{
			{
				InstancePort:     80,
				InstanceProtocol: "http",
				Protocol:         "http",
				LoadBalancerPort: 80,
			},
			{
				InstancePort:     8080,
				InstanceProtocol: "http",
				Protocol:         "http",
				LoadBalancerPort: 8080,
			},
		},
		Subnets:        []string{"subnetid-1", "subnetid-2"},
		SecurityGroups: []string{"sg-1", "sg-2"},
	}
	_, err := s.elb.CreateLoadBalancer(createLB)
	c.Assert(err, gocheck.IsNil)
	defer s.elb.DeleteLoadBalancer(createLB.Name)
	values := testServer.WaitRequest().URL.Query()
	c.Assert(values.Get("Listeners.member.1.InstancePort"), gocheck.Equals, "80")
	c.Assert(values.Get("Listeners.member.1.LoadBalancerPort"), gocheck.Equals, "80")
	c.Assert(values.Get("Listeners.member.2.InstancePort"), gocheck.Equals, "8080")
	c.Assert(values.Get("Listeners.member.2.LoadBalancerPort"), gocheck.Equals, "8080")
	c.Assert(values.Get("Subnets.member.1"), gocheck.Equals, "subnetid-1")
	c.Assert(values.Get("Subnets.member.2"), gocheck.Equals, "subnetid-2")
	c.Assert(values.Get("SecurityGroups.member.1"), gocheck.Equals, "sg-1")
	c.Assert(values.Get("SecurityGroups.member.2"), gocheck.Equals, "sg-2")
}

func (s *S) TestCreateLoadBalancerWithWrongParamsCombination(c *gocheck.C) {
	testServer.PrepareResponse(400, nil, CreateLoadBalancerBadRequest)
	createLB := &elb.CreateLoadBalancer{
		Name:              "testlb",
		AvailabilityZones: []string{"us-east-1a", "us-east-1b"},
		Listeners: []elb.Listener{
			{
				InstancePort:     80,
				InstanceProtocol: "http",
				Protocol:         "http",
				LoadBalancerPort: 80,
			},
		},
		Subnets: []string{"subnetid-1", "subnetid2"},
	}
	resp, err := s.elb.CreateLoadBalancer(createLB)
	c.Assert(resp, gocheck.IsNil)
	c.Assert(err, gocheck.NotNil)
	e, ok := err.(*elb.Error)
	c.Assert(ok, gocheck.Equals, true)
	c.Assert(e.Message, gocheck.Equals, "Only one of SubnetIds or AvailabilityZones may be specified")
	c.Assert(e.Code, gocheck.Equals, "ValidationError")
}

func (s *S) TestDeleteLoadBalancer(c *gocheck.C) {
	testServer.PrepareResponse(200, nil, DeleteLoadBalancer)
	resp, err := s.elb.DeleteLoadBalancer("testlb")
	c.Assert(err, gocheck.IsNil)
	values := testServer.WaitRequest().URL.Query()
	c.Assert(values.Get("Version"), gocheck.Equals, "2012-06-01")
	c.Assert(values.Get("Signature"), gocheck.Not(gocheck.Equals), "")
	c.Assert(values.Get("Timestamp"), gocheck.Not(gocheck.Equals), "")
	c.Assert(values.Get("Action"), gocheck.Equals, "DeleteLoadBalancer")
	c.Assert(values.Get("LoadBalancerName"), gocheck.Equals, "testlb")
	c.Assert(resp.RequestId, gocheck.Equals, "8d7223db-49d7-11e2-bba9-35ba56032fe1")
}

func (s *S) TestRegisterInstancesWithLoadBalancer(c *gocheck.C) {
	testServer.PrepareResponse(200, nil, RegisterInstancesWithLoadBalancer)
	resp, err := s.elb.RegisterInstancesWithLoadBalancer([]string{"i-b44db8ca", "i-461ecf38"}, "testlb")
	c.Assert(err, gocheck.IsNil)
	values := testServer.WaitRequest().URL.Query()
	c.Assert(values.Get("Version"), gocheck.Equals, "2012-06-01")
	c.Assert(values.Get("Signature"), gocheck.Not(gocheck.Equals), "")
	c.Assert(values.Get("Timestamp"), gocheck.Not(gocheck.Equals), "")
	c.Assert(values.Get("Action"), gocheck.Equals, "RegisterInstancesWithLoadBalancer")
	c.Assert(values.Get("LoadBalancerName"), gocheck.Equals, "testlb")
	c.Assert(values.Get("Instances.member.1.InstanceId"), gocheck.Equals, "i-b44db8ca")
	c.Assert(values.Get("Instances.member.2.InstanceId"), gocheck.Equals, "i-461ecf38")
	c.Assert(resp.InstanceIds, gocheck.DeepEquals, []string{"i-b44db8ca", "i-461ecf38"})
}

func (s *S) TestRegisterInstancesWithLoadBalancerBadRequest(c *gocheck.C) {
	testServer.PrepareResponse(400, nil, RegisterInstancesWithLoadBalancerBadRequest)
	resp, err := s.elb.RegisterInstancesWithLoadBalancer([]string{"i-b44db8ca", "i-461ecf38"}, "absentLB")
	c.Assert(resp, gocheck.IsNil)
	c.Assert(err, gocheck.NotNil)
	e, ok := err.(*elb.Error)
	c.Assert(ok, gocheck.Equals, true)
	c.Assert(e.Message, gocheck.Equals, "There is no ACTIVE Load Balancer named 'absentLB'")
	c.Assert(e.Code, gocheck.Equals, "LoadBalancerNotFound")
}

func (s *S) TestDeregisterInstancesFromLoadBalancer(c *gocheck.C) {
	testServer.PrepareResponse(200, nil, DeregisterInstancesFromLoadBalancer)
	resp, err := s.elb.DeregisterInstancesFromLoadBalancer([]string{"i-b44db8ca", "i-461ecf38"}, "testlb")
	c.Assert(err, gocheck.IsNil)
	values := testServer.WaitRequest().URL.Query()
	c.Assert(values.Get("Version"), gocheck.Equals, "2012-06-01")
	c.Assert(values.Get("Signature"), gocheck.Not(gocheck.Equals), "")
	c.Assert(values.Get("Timestamp"), gocheck.Not(gocheck.Equals), "")
	c.Assert(values.Get("Action"), gocheck.Equals, "DeregisterInstancesFromLoadBalancer")
	c.Assert(values.Get("LoadBalancerName"), gocheck.Equals, "testlb")
	c.Assert(values.Get("Instances.member.1.InstanceId"), gocheck.Equals, "i-b44db8ca")
	c.Assert(values.Get("Instances.member.2.InstanceId"), gocheck.Equals, "i-461ecf38")
	c.Assert(resp.RequestId, gocheck.Equals, "d6490837-49fd-11e2-bba9-35ba56032fe1")
}

func (s *S) TestDeregisterInstancesFromLoadBalancerBadRequest(c *gocheck.C) {
	testServer.PrepareResponse(400, nil, DeregisterInstancesFromLoadBalancerBadRequest)
	resp, err := s.elb.DeregisterInstancesFromLoadBalancer([]string{"i-b44db8ca", "i-461ecf38"}, "testlb")
	c.Assert(resp, gocheck.IsNil)
	c.Assert(err, gocheck.NotNil)
	e, ok := err.(*elb.Error)
	c.Assert(ok, gocheck.Equals, true)
	c.Assert(e.Message, gocheck.Equals, "There is no ACTIVE Load Balancer named 'absentlb'")
	c.Assert(e.Code, gocheck.Equals, "LoadBalancerNotFound")
}

func (s *S) TestDescribeLoadBalancers(c *gocheck.C) {
	testServer.PrepareResponse(200, nil, DescribeLoadBalancers)
	resp, err := s.elb.DescribeLoadBalancers()
	c.Assert(err, gocheck.IsNil)
	values := testServer.WaitRequest().URL.Query()
	c.Assert(values.Get("Version"), gocheck.Equals, "2012-06-01")
	c.Assert(values.Get("Signature"), gocheck.Not(gocheck.Equals), "")
	c.Assert(values.Get("Timestamp"), gocheck.Not(gocheck.Equals), "")
	c.Assert(values.Get("Action"), gocheck.Equals, "DescribeLoadBalancers")
	t, _ := time.Parse(time.RFC3339, "2012-12-27T11:51:52.970Z")
	expected := &elb.DescribeLoadBalancerResp{
		[]elb.LoadBalancerDescription{
			{
				AvailabilityZones:         []string{"us-east-1a"},
				BackendServerDescriptions: []elb.BackendServerDescriptions(nil),
				CanonicalHostedZoneName:   "testlb-2087227216.us-east-1.elb.amazonaws.com",
				CanonicalHostedZoneNameId: "Z3DZXE0Q79N41H",
				CreatedTime:               t,
				DNSName:                   "testlb-2087227216.us-east-1.elb.amazonaws.com",
				HealthCheck: elb.HealthCheck{
					HealthyThreshold:   10,
					Interval:           30,
					Target:             "TCP:80",
					Timeout:            5,
					UnhealthyThreshold: 2,
				},
				Instances: []elb.Instance(nil),
				ListenerDescriptions: []elb.ListenerDescription{
					{
						Listener: elb.Listener{
							Protocol:         "HTTP",
							LoadBalancerPort: 80,
							InstanceProtocol: "HTTP",
							InstancePort:     80,
						},
					},
				},
				LoadBalancerName: "testlb",
				//Policies:                  elb.Policies(nil),
				Scheme:         "internet-facing",
				SecurityGroups: []string(nil),
				SourceSecurityGroup: elb.SourceSecurityGroup{
					GroupName:  "amazon-elb-sg",
					OwnerAlias: "amazon-elb",
				},
				Subnets: []string(nil),
			},
		},
	}
	c.Assert(resp, gocheck.DeepEquals, expected)
}

func (s *S) TestDescribeLoadBalancersByName(c *gocheck.C) {
	testServer.PrepareResponse(200, nil, DescribeLoadBalancers)
	s.elb.DescribeLoadBalancers("somelb")
	values := testServer.WaitRequest().URL.Query()
	c.Assert(values.Get("Version"), gocheck.Equals, "2012-06-01")
	c.Assert(values.Get("Signature"), gocheck.Not(gocheck.Equals), "")
	c.Assert(values.Get("Timestamp"), gocheck.Not(gocheck.Equals), "")
	c.Assert(values.Get("Action"), gocheck.Equals, "DescribeLoadBalancers")
	c.Assert(values.Get("LoadBalancerNames.member.1"), gocheck.Equals, "somelb")
}

func (s *S) TestDescribeLoadBalancersBadRequest(c *gocheck.C) {
	testServer.PrepareResponse(400, nil, DescribeLoadBalancersBadRequest)
	resp, err := s.elb.DescribeLoadBalancers()
	c.Assert(resp, gocheck.IsNil)
	c.Assert(err, gocheck.NotNil)
	c.Assert(err, gocheck.ErrorMatches, `^Cannot find Load Balancer absentlb \(LoadBalancerNotFound\)$`)
}

func (s *S) TestDescribeInstanceHealth(c *gocheck.C) {
	testServer.PrepareResponse(200, nil, DescribeInstanceHealth)
	resp, err := s.elb.DescribeInstanceHealth("testlb", "i-b44db8ca")
	c.Assert(err, gocheck.IsNil)
	values := testServer.WaitRequest().URL.Query()
	c.Assert(values.Get("Version"), gocheck.Equals, "2012-06-01")
	c.Assert(values.Get("Signature"), gocheck.Not(gocheck.Equals), "")
	c.Assert(values.Get("Timestamp"), gocheck.Not(gocheck.Equals), "")
	c.Assert(values.Get("Action"), gocheck.Equals, "DescribeInstanceHealth")
	c.Assert(values.Get("LoadBalancerName"), gocheck.Equals, "testlb")
	c.Assert(values.Get("Instances.member.1.InstanceId"), gocheck.Equals, "i-b44db8ca")
	c.Assert(len(resp.InstanceStates) > 0, gocheck.Equals, true)
	c.Assert(resp.InstanceStates[0].Description, gocheck.Equals, "Instance registration is still in progress.")
	c.Assert(resp.InstanceStates[0].InstanceId, gocheck.Equals, "i-b44db8ca")
	c.Assert(resp.InstanceStates[0].State, gocheck.Equals, "OutOfService")
	c.Assert(resp.InstanceStates[0].ReasonCode, gocheck.Equals, "ELB")
}

func (s *S) TestDescribeInstanceHealthBadRequest(c *gocheck.C) {
	testServer.PrepareResponse(400, nil, DescribeInstanceHealthBadRequest)
	resp, err := s.elb.DescribeInstanceHealth("testlb", "i-foooo")
	c.Assert(err, gocheck.NotNil)
	c.Assert(resp, gocheck.IsNil)
	c.Assert(err, gocheck.ErrorMatches, ".*i-foooo.*(InvalidInstance).*")
}

func (s *S) TestConfigureHealthCheck(c *gocheck.C) {
	testServer.PrepareResponse(200, nil, ConfigureHealthCheck)
	hc := elb.HealthCheck{
		HealthyThreshold:   10,
		Interval:           30,
		Target:             "HTTP:80/",
		Timeout:            5,
		UnhealthyThreshold: 2,
	}
	resp, err := s.elb.ConfigureHealthCheck("testlb", &hc)
	c.Assert(err, gocheck.IsNil)
	values := testServer.WaitRequest().URL.Query()
	c.Assert(values.Get("Version"), gocheck.Equals, "2012-06-01")
	c.Assert(values.Get("Signature"), gocheck.Not(gocheck.Equals), "")
	c.Assert(values.Get("Timestamp"), gocheck.Not(gocheck.Equals), "")
	c.Assert(values.Get("Action"), gocheck.Equals, "ConfigureHealthCheck")
	c.Assert(values.Get("LoadBalancerName"), gocheck.Equals, "testlb")
	c.Assert(values.Get("HealthCheck.HealthyThreshold"), gocheck.Equals, "10")
	c.Assert(values.Get("HealthCheck.Interval"), gocheck.Equals, "30")
	c.Assert(values.Get("HealthCheck.Target"), gocheck.Equals, "HTTP:80/")
	c.Assert(values.Get("HealthCheck.Timeout"), gocheck.Equals, "5")
	c.Assert(values.Get("HealthCheck.UnhealthyThreshold"), gocheck.Equals, "2")
	c.Assert(resp.HealthCheck.HealthyThreshold, gocheck.Equals, 10)
	c.Assert(resp.HealthCheck.Interval, gocheck.Equals, 30)
	c.Assert(resp.HealthCheck.Target, gocheck.Equals, "HTTP:80/")
	c.Assert(resp.HealthCheck.Timeout, gocheck.Equals, 5)
	c.Assert(resp.HealthCheck.UnhealthyThreshold, gocheck.Equals, 2)
}

func (s *S) TestConfigureHealthCheckBadRequest(c *gocheck.C) {
	testServer.PrepareResponse(400, nil, ConfigureHealthCheckBadRequest)
	hc := elb.HealthCheck{
		HealthyThreshold:   10,
		Interval:           30,
		Target:             "HTTP:80/",
		Timeout:            5,
		UnhealthyThreshold: 2,
	}
	resp, err := s.elb.ConfigureHealthCheck("foolb", &hc)
	c.Assert(resp, gocheck.IsNil)
	c.Assert(err, gocheck.NotNil)
	c.Assert(err, gocheck.ErrorMatches, ".*foolb.*(LoadBalancerNotFound).*")
}
