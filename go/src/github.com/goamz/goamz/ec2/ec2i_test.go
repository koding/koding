package ec2_test

import (
	"crypto/rand"
	"fmt"
	"github.com/goamz/goamz/aws"
	"github.com/goamz/goamz/ec2"
	"github.com/goamz/goamz/testutil"
	"github.com/motain/gocheck"
)

// AmazonServer represents an Amazon EC2 server.
type AmazonServer struct {
	auth aws.Auth
}

func (s *AmazonServer) SetUp(c *gocheck.C) {
	auth, err := aws.EnvAuth()
	if err != nil {
		c.Fatal(err.Error())
	}
	s.auth = auth
}

// Suite cost per run: 0.02 USD
var _ = gocheck.Suite(&AmazonClientSuite{})

// AmazonClientSuite tests the client against a live EC2 server.
type AmazonClientSuite struct {
	srv AmazonServer
	ClientTests
}

func (s *AmazonClientSuite) SetUpSuite(c *gocheck.C) {
	if !testutil.Amazon {
		c.Skip("AmazonClientSuite tests not enabled")
	}
	s.srv.SetUp(c)
	s.ec2 = ec2.NewWithClient(s.srv.auth, aws.USEast, testutil.DefaultClient)
}

// ClientTests defines integration tests designed to test the client.
// It is not used as a test suite in itself, but embedded within
// another type.
type ClientTests struct {
	ec2 *ec2.EC2
}

var imageId = "ami-ccf405a5" // Ubuntu Maverick, i386, EBS store

// Cost: 0.00 USD
func (s *ClientTests) TestRunInstancesError(c *gocheck.C) {
	options := ec2.RunInstancesOptions{
		ImageId:      "ami-a6f504cf", // Ubuntu Maverick, i386, instance store
		InstanceType: "t1.micro",     // Doesn't work with micro, results in 400.
	}

	resp, err := s.ec2.RunInstances(&options)

	c.Assert(resp, gocheck.IsNil)
	c.Assert(err, gocheck.ErrorMatches, "AMI.*root device.*not supported.*")

	ec2err, ok := err.(*ec2.Error)
	c.Assert(ok, gocheck.Equals, true)
	c.Assert(ec2err.StatusCode, gocheck.Equals, 400)
	c.Assert(ec2err.Code, gocheck.Equals, "UnsupportedOperation")
	c.Assert(ec2err.Message, gocheck.Matches, "AMI.*root device.*not supported.*")
	c.Assert(ec2err.RequestId, gocheck.Matches, ".+")
}

// Cost: 0.02 USD
func (s *ClientTests) TestRunAndTerminate(c *gocheck.C) {
	options := ec2.RunInstancesOptions{
		ImageId:      imageId,
		InstanceType: "t1.micro",
	}
	resp1, err := s.ec2.RunInstances(&options)
	c.Assert(err, gocheck.IsNil)
	c.Check(resp1.ReservationId, gocheck.Matches, "r-[0-9a-f]*")
	c.Check(resp1.OwnerId, gocheck.Matches, "[0-9]+")
	c.Check(resp1.Instances, gocheck.HasLen, 1)
	c.Check(resp1.Instances[0].InstanceType, gocheck.Equals, "t1.micro")

	instId := resp1.Instances[0].InstanceId

	resp2, err := s.ec2.DescribeInstances([]string{instId}, nil)
	c.Assert(err, gocheck.IsNil)
	if c.Check(resp2.Reservations, gocheck.HasLen, 1) && c.Check(len(resp2.Reservations[0].Instances), gocheck.Equals, 1) {
		inst := resp2.Reservations[0].Instances[0]
		c.Check(inst.InstanceId, gocheck.Equals, instId)
	}

	resp3, err := s.ec2.TerminateInstances([]string{instId})
	c.Assert(err, gocheck.IsNil)
	c.Check(resp3.StateChanges, gocheck.HasLen, 1)
	c.Check(resp3.StateChanges[0].InstanceId, gocheck.Equals, instId)
	c.Check(resp3.StateChanges[0].CurrentState.Name, gocheck.Equals, "shutting-down")
	c.Check(resp3.StateChanges[0].CurrentState.Code, gocheck.Equals, 32)
}

// Cost: 0.00 USD
func (s *ClientTests) TestSecurityGroups(c *gocheck.C) {
	name := "goamz-test"
	descr := "goamz security group for tests"

	// Clean it up, if a previous test left it around and avoid leaving it around.
	s.ec2.DeleteSecurityGroup(ec2.SecurityGroup{Name: name})
	defer s.ec2.DeleteSecurityGroup(ec2.SecurityGroup{Name: name})

	resp1, err := s.ec2.CreateSecurityGroup(ec2.SecurityGroup{Name: name, Description: descr})
	c.Assert(err, gocheck.IsNil)
	c.Assert(resp1.RequestId, gocheck.Matches, ".+")
	c.Assert(resp1.Name, gocheck.Equals, name)
	c.Assert(resp1.Id, gocheck.Matches, ".+")

	resp1, err = s.ec2.CreateSecurityGroup(ec2.SecurityGroup{Name: name, Description: descr})
	ec2err, _ := err.(*ec2.Error)
	c.Assert(resp1, gocheck.IsNil)
	c.Assert(ec2err, gocheck.NotNil)
	c.Assert(ec2err.Code, gocheck.Equals, "InvalidGroup.Duplicate")

	perms := []ec2.IPPerm{{
		Protocol:  "tcp",
		FromPort:  0,
		ToPort:    1024,
		SourceIPs: []string{"127.0.0.1/24"},
	}}

	resp2, err := s.ec2.AuthorizeSecurityGroup(ec2.SecurityGroup{Name: name}, perms)
	c.Assert(err, gocheck.IsNil)
	c.Assert(resp2.RequestId, gocheck.Matches, ".+")

	resp3, err := s.ec2.SecurityGroups(ec2.SecurityGroupNames(name), nil)
	c.Assert(err, gocheck.IsNil)
	c.Assert(resp3.RequestId, gocheck.Matches, ".+")
	c.Assert(resp3.Groups, gocheck.HasLen, 1)

	g0 := resp3.Groups[0]
	c.Assert(g0.Name, gocheck.Equals, name)
	c.Assert(g0.Description, gocheck.Equals, descr)
	c.Assert(g0.IPPerms, gocheck.HasLen, 1)
	c.Assert(g0.IPPerms[0].Protocol, gocheck.Equals, "tcp")
	c.Assert(g0.IPPerms[0].FromPort, gocheck.Equals, 0)
	c.Assert(g0.IPPerms[0].ToPort, gocheck.Equals, 1024)
	c.Assert(g0.IPPerms[0].SourceIPs, gocheck.DeepEquals, []string{"127.0.0.1/24"})

	resp2, err = s.ec2.DeleteSecurityGroup(ec2.SecurityGroup{Name: name})
	c.Assert(err, gocheck.IsNil)
	c.Assert(resp2.RequestId, gocheck.Matches, ".+")
}

var sessionId = func() string {
	buf := make([]byte, 8)
	// if we have no randomness, we'll just make do, so ignore the error.
	rand.Read(buf)
	return fmt.Sprintf("%x", buf)
}()

// sessionName reutrns a name that is probably
// unique to this test session.
func sessionName(prefix string) string {
	return prefix + "-" + sessionId
}

var allRegions = []aws.Region{
	aws.USEast,
	aws.USWest,
	aws.EUWest,
	aws.APSoutheast,
	aws.APNortheast,
}

// Communicate with all EC2 endpoints to see if they are alive.
func (s *ClientTests) TestRegions(c *gocheck.C) {
	name := sessionName("goamz-region-test")
	perms := []ec2.IPPerm{{
		Protocol:  "tcp",
		FromPort:  80,
		ToPort:    80,
		SourceIPs: []string{"127.0.0.1/32"},
	}}
	errs := make(chan error, len(allRegions))
	for _, region := range allRegions {
		go func(r aws.Region) {
			e := ec2.NewWithClient(s.ec2.Auth, r, testutil.DefaultClient)
			_, err := e.AuthorizeSecurityGroup(ec2.SecurityGroup{Name: name}, perms)
			errs <- err
		}(region)
	}
	for _ = range allRegions {
		err := <-errs
		if err != nil {
			ec2_err, ok := err.(*ec2.Error)
			if ok {
				c.Check(ec2_err.Code, gocheck.Matches, "InvalidGroup.NotFound")
			} else {
				c.Errorf("Non-EC2 error: %s", err)
			}
		} else {
			c.Errorf("Test should have errored but it seems to have succeeded")
		}
	}
}
