package rds_test

import (
	"github.com/goamz/goamz/aws"
	"github.com/goamz/goamz/rds"
	"github.com/goamz/goamz/testutil"
	"github.com/motain/gocheck"
	"testing"
)

func Test(t *testing.T) {
	gocheck.TestingT(t)
}

var _ = gocheck.Suite(&S{})

type S struct {
	rds *rds.RDS
}

var testServer = testutil.NewHTTPServer()

func (s *S) SetUpSuite(c *gocheck.C) {
	var err error
	testServer.Start()
	auth := aws.Auth{AccessKey: "abc", SecretKey: "123"}
	s.rds, err = rds.New(auth, aws.Region{RDSEndpoint: aws.ServiceInfo{testServer.URL, aws.V2Signature}})
	c.Assert(err, gocheck.IsNil)
}

func (s *S) TearDownTest(c *gocheck.C) {
	testServer.Flush()
}

func (s *S) TestDescribeDBInstancesExample1(c *gocheck.C) {
	testServer.Response(200, nil, DescribeDBInstancesExample1)

	resp, err := s.rds.DescribeDBInstances("simcoprod01", 0, "")

	req := testServer.WaitRequest()
	c.Assert(req.Form["Action"], gocheck.DeepEquals, []string{"DescribeDBInstances"})
	c.Assert(req.Form["DBInstanceIdentifier"], gocheck.DeepEquals, []string{"simcoprod01"})

	c.Assert(err, gocheck.IsNil)
	c.Assert(resp.RequestId, gocheck.Equals, "9135fff3-8509-11e0-bd9b-a7b1ece36d51")
	c.Assert(resp.DBInstances, gocheck.HasLen, 1)

	db0 := resp.DBInstances[0]
	c.Assert(db0.AllocatedStorage, gocheck.Equals, 10)
	c.Assert(db0.AutoMinorVersionUpgrade, gocheck.Equals, true)
	c.Assert(db0.AvailabilityZone, gocheck.Equals, "us-east-1a")
	c.Assert(db0.BackupRetentionPeriod, gocheck.Equals, 1)

	c.Assert(db0.DBInstanceClass, gocheck.Equals, "db.m1.large")
	c.Assert(db0.DBInstanceIdentifier, gocheck.Equals, "simcoprod01")
	c.Assert(db0.DBInstanceStatus, gocheck.Equals, "available")
	c.Assert(db0.DBName, gocheck.Equals, "simcoprod")

	c.Assert(db0.Endpoint.Address, gocheck.Equals, "simcoprod01.cu7u2t4uz396.us-east-1.rds.amazonaws.com")
	c.Assert(db0.Endpoint.Port, gocheck.Equals, 3306)
	c.Assert(db0.Engine, gocheck.Equals, "mysql")
	c.Assert(db0.EngineVersion, gocheck.Equals, "5.1.50")
	c.Assert(db0.InstanceCreateTime, gocheck.Equals, "2011-05-23T06:06:43.110Z")

	c.Assert(db0.LatestRestorableTime, gocheck.Equals, "2011-05-23T06:50:00Z")
	c.Assert(db0.LicenseModel, gocheck.Equals, "general-public-license")
	c.Assert(db0.MasterUsername, gocheck.Equals, "master")
	c.Assert(db0.MultiAZ, gocheck.Equals, false)
	c.Assert(db0.OptionGroupMemberships, gocheck.HasLen, 1)
	c.Assert(db0.OptionGroupMemberships[0].Name, gocheck.Equals, "default.mysql5.1")
	c.Assert(db0.OptionGroupMemberships[0].Status, gocheck.Equals, "in-sync")

	c.Assert(db0.PreferredBackupWindow, gocheck.Equals, "00:00-00:30")
	c.Assert(db0.PreferredMaintenanceWindow, gocheck.Equals, "sat:07:30-sat:08:00")
	c.Assert(db0.PubliclyAccessible, gocheck.Equals, false)
}
