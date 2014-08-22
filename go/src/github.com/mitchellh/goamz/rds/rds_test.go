package rds_test

import (
	"github.com/mitchellh/goamz/aws"
	"github.com/mitchellh/goamz/rds"
	"github.com/mitchellh/goamz/testutil"
	. "github.com/motain/gocheck"
	"testing"
)

func Test(t *testing.T) {
	TestingT(t)
}

type S struct {
	rds *rds.Rds
}

var _ = Suite(&S{})

var testServer = testutil.NewHTTPServer()

func (s *S) SetUpSuite(c *C) {
	testServer.Start()
	auth := aws.Auth{"abc", "123", ""}
	s.rds = rds.NewWithClient(auth, aws.Region{RdsEndpoint: testServer.URL}, testutil.DefaultClient)
}

func (s *S) TearDownTest(c *C) {
	testServer.Flush()
}

func (s *S) Test_CreateDBInstance(c *C) {
	testServer.Response(200, nil, CreateDBInstanceExample)

	options := rds.CreateDBInstance{
		BackupRetentionPeriod:      30,
		MultiAZ:                    false,
		DBInstanceIdentifier:       "foobarbaz",
		PreferredBackupWindow:      "10:07-10:37",
		PreferredMaintenanceWindow: "sun:06:13-sun:06:43",
		AvailabilityZone:           "us-west-2b",
		Engine:                     "mysql",
		EngineVersion:              "",
		DBName:                     "5.6.13",
		AllocatedStorage:           10,
		MasterUsername:             "foobar",
		MasterUserPassword:         "bazbarbaz",
		DBInstanceClass:            "db.m1.small",
		DBSecurityGroupNames:       []string{"foo", "bar"},

		SetBackupRetentionPeriod: true,
	}

	resp, err := s.rds.CreateDBInstance(&options)
	req := testServer.WaitRequest()

	c.Assert(req.Form["Action"], DeepEquals, []string{"CreateDBInstance"})
	c.Assert(req.Form["Engine"], DeepEquals, []string{"mysql"})
	c.Assert(req.Form["DBSecurityGroups.member.1"], DeepEquals, []string{"foo"})
	c.Assert(err, IsNil)
	c.Assert(resp.RequestId, Equals, "523e3218-afc7-11c3-90f5-f90431260ab4")
}

func (s *S) Test_CreateDBSecurityGroup(c *C) {
	testServer.Response(200, nil, CreateDBSecurityGroupExample)

	options := rds.CreateDBSecurityGroup{
		DBSecurityGroupName:        "foobarbaz",
		DBSecurityGroupDescription: "test description",
	}

	resp, err := s.rds.CreateDBSecurityGroup(&options)
	req := testServer.WaitRequest()

	c.Assert(req.Form["Action"], DeepEquals, []string{"CreateDBSecurityGroup"})
	c.Assert(req.Form["DBSecurityGroupName"], DeepEquals, []string{"foobarbaz"})
	c.Assert(req.Form["DBSecurityGroupDescription"], DeepEquals, []string{"test description"})
	c.Assert(err, IsNil)
	c.Assert(resp.RequestId, Equals, "e68ef6fa-afc1-11c3-845a-476777009d19")
}

func (s *S) Test_CreateDBSubnetGroup(c *C) {
	testServer.Response(200, nil, CreateDBSubnetGroupExample)

	options := rds.CreateDBSubnetGroup{
		DBSubnetGroupName:        "foobarbaz",
		DBSubnetGroupDescription: "test description",
		SubnetIds:                []string{"subnet-e4d398a1", "subnet-c2bdb6ba"},
	}

	resp, err := s.rds.CreateDBSubnetGroup(&options)
	req := testServer.WaitRequest()

	c.Assert(req.Form["Action"], DeepEquals, []string{"CreateDBSubnetGroup"})
	c.Assert(req.Form["DBSubnetGroupName"], DeepEquals, []string{"foobarbaz"})
	c.Assert(req.Form["DBSubnetGroupDescription"], DeepEquals, []string{"test description"})
	c.Assert(req.Form["SubnetIds.member.1"], DeepEquals, []string{"subnet-e4d398a1"})
	c.Assert(req.Form["SubnetIds.member.2"], DeepEquals, []string{"subnet-c2bdb6ba"})
	c.Assert(err, IsNil)
	c.Assert(resp.RequestId, Equals, "3a401b3f-bb9e-11d3-f4c6-37db295f7674")
}

func (s *S) Test_DescribeDBInstances(c *C) {
	testServer.Response(200, nil, DescribeDBInstancesExample)

	options := rds.DescribeDBInstances{
		DBInstanceIdentifier: "foobarbaz",
	}

	resp, err := s.rds.DescribeDBInstances(&options)
	req := testServer.WaitRequest()

	c.Assert(req.Form["Action"], DeepEquals, []string{"DescribeDBInstances"})
	c.Assert(req.Form["DBInstanceIdentifier"], DeepEquals, []string{"foobarbaz"})
	c.Assert(err, IsNil)
	c.Assert(resp.RequestId, Equals, "01b2685a-b978-11d3-f272-7cd6cce12cc5")
	c.Assert(resp.DBInstances[0].DBName, Equals, "mysampledb")
	c.Assert(resp.DBInstances[0].DBSecurityGroupNames, DeepEquals, []string{"my-db-secgroup"})
}

func (s *S) Test_DescribeDBSecurityGroups(c *C) {
	testServer.Response(200, nil, DescribeDBSecurityGroupsExample)

	options := rds.DescribeDBSecurityGroups{
		DBSecurityGroupName: "foobarbaz",
	}

	resp, err := s.rds.DescribeDBSecurityGroups(&options)
	req := testServer.WaitRequest()

	c.Assert(req.Form["Action"], DeepEquals, []string{"DescribeDBSecurityGroups"})
	c.Assert(req.Form["DBSecurityGroupName"], DeepEquals, []string{"foobarbaz"})
	c.Assert(err, IsNil)
	c.Assert(resp.RequestId, Equals, "b76e692c-b98c-11d3-a907-5a2c468b9cb0")
	c.Assert(resp.DBSecurityGroups[0].EC2SecurityGroupIds, DeepEquals, []string{"sg-7f476617"})
	c.Assert(resp.DBSecurityGroups[0].EC2SecurityGroupOwnerIds, DeepEquals, []string{"803#########"})
	c.Assert(resp.DBSecurityGroups[0].EC2SecurityGroupStatuses, DeepEquals, []string{"authorized"})
	c.Assert(resp.DBSecurityGroups[0].CidrIps, DeepEquals, []string{"192.0.0.0/24", "190.0.1.0/29", "190.0.2.0/29", "10.0.0.0/8"})
	c.Assert(resp.DBSecurityGroups[0].CidrStatuses, DeepEquals, []string{"authorized", "authorized", "authorized", "authorized"})
}

func (s *S) Test_DescribeDBSubnetGroups(c *C) {
	testServer.Response(200, nil, DescribeDBSubnetGroupsExample)

	options := rds.DescribeDBSubnetGroups{
		DBSubnetGroupName: "foobarbaz",
	}

	resp, err := s.rds.DescribeDBSubnetGroups(&options)
	req := testServer.WaitRequest()

	c.Assert(req.Form["Action"], DeepEquals, []string{"DescribeDBSubnetGroups"})
	c.Assert(req.Form["DBSubnetGroupName"], DeepEquals, []string{"foobarbaz"})
	c.Assert(err, IsNil)
	c.Assert(resp.RequestId, Equals, "b783db3b-b98c-11d3-fbc7-5c0aad74da7c")
	c.Assert(resp.DBSubnetGroups[0].Status, DeepEquals, "Complete")
	c.Assert(resp.DBSubnetGroups[0].SubnetIds, DeepEquals, []string{"subnet-e8b3e5b1", "subnet-44b2f22e"})
	c.Assert(resp.DBSubnetGroups[0].VpcId, DeepEquals, "vpc-e7abbdce")
}

func (s *S) Test_DeleteDBInstance(c *C) {
	testServer.Response(200, nil, DeleteDBInstanceExample)

	options := rds.DeleteDBInstance{
		DBInstanceIdentifier: "foobarbaz",
		SkipFinalSnapshot:    true,
	}

	resp, err := s.rds.DeleteDBInstance(&options)
	req := testServer.WaitRequest()

	c.Assert(req.Form["Action"], DeepEquals, []string{"DeleteDBInstance"})
	c.Assert(req.Form["DBInstanceIdentifier"], DeepEquals, []string{"foobarbaz"})
	c.Assert(req.Form["SkipFinalSnapshot"], DeepEquals, []string{"true"})
	c.Assert(err, IsNil)
	c.Assert(resp.RequestId, Equals, "7369556f-b70d-11c3-faca-6ba18376ea1b")
}

func (s *S) Test_DeleteDBInstance_SnapshotIdentifier(c *C) {
	testServer.Response(200, nil, DeleteDBInstanceExample)

	options := rds.DeleteDBInstance{
		DBInstanceIdentifier:      "foobarbaz",
		SkipFinalSnapshot:         false,
		FinalDBSnapshotIdentifier: "bar",
	}

	resp, err := s.rds.DeleteDBInstance(&options)
	req := testServer.WaitRequest()

	c.Assert(req.Form["Action"], DeepEquals, []string{"DeleteDBInstance"})
	c.Assert(req.Form["DBInstanceIdentifier"], DeepEquals, []string{"foobarbaz"})
	c.Assert(req.Form["FinalDBSnapshotIdentifier"], DeepEquals, []string{"bar"})
	c.Assert(req.Form["SkipFinalSnapshot"], IsNil)
	c.Assert(err, IsNil)
	c.Assert(resp.RequestId, Equals, "7369556f-b70d-11c3-faca-6ba18376ea1b")
}

func (s *S) Test_DeleteDBSecurityGroup(c *C) {
	testServer.Response(200, nil, DeleteDBSecurityGroupExample)

	options := rds.DeleteDBSecurityGroup{
		DBSecurityGroupName: "foobarbaz",
	}

	resp, err := s.rds.DeleteDBSecurityGroup(&options)
	req := testServer.WaitRequest()

	c.Assert(req.Form["Action"], DeepEquals, []string{"DeleteDBSecurityGroup"})
	c.Assert(req.Form["DBSecurityGroupName"], DeepEquals, []string{"foobarbaz"})
	c.Assert(err, IsNil)
	c.Assert(resp.RequestId, Equals, "7aec7454-ba25-11d3-855b-576787000e19")
}

func (s *S) Test_DeleteDBSubnetGroup(c *C) {
	testServer.Response(200, nil, DeleteDBSubnetGroupExample)

	options := rds.DeleteDBSubnetGroup{
		DBSubnetGroupName: "foobarbaz",
	}

	resp, err := s.rds.DeleteDBSubnetGroup(&options)
	req := testServer.WaitRequest()

	c.Assert(req.Form["Action"], DeepEquals, []string{"DeleteDBSubnetGroup"})
	c.Assert(req.Form["DBSubnetGroupName"], DeepEquals, []string{"foobarbaz"})
	c.Assert(err, IsNil)
	c.Assert(resp.RequestId, Equals, "6295e5ab-bbf3-11d3-f4c6-37db295f7674")
}

func (s *S) Test_AuthorizeDBSecurityGroupIngress(c *C) {
	testServer.Response(200, nil, AuthorizeDBSecurityGroupIngressExample)

	options := rds.AuthorizeDBSecurityGroupIngress{
		DBSecurityGroupName:     "foobarbaz",
		EC2SecurityGroupOwnerId: "bar",
	}

	resp, err := s.rds.AuthorizeDBSecurityGroupIngress(&options)
	req := testServer.WaitRequest()

	c.Assert(req.Form["Action"], DeepEquals, []string{"AuthorizeDBSecurityGroupIngress"})
	c.Assert(req.Form["DBSecurityGroupName"], DeepEquals, []string{"foobarbaz"})
	c.Assert(req.Form["EC2SecurityGroupOwnerId"], DeepEquals, []string{"bar"})
	c.Assert(err, IsNil)
	c.Assert(resp.RequestId, Equals, "6176b5f8-bfed-11d3-f92b-31fa5e8dbc99")
}

func (s *S) Test_DescribeDBSnapshots(c *C) {
	testServer.Response(200, nil, DescribeDBSnapshotsExample)

	options := rds.DescribeDBSnapshots{
		DBInstanceIdentifier: "foobar",
		DBSnapshotIdentifier: "baz",
		SnapshotType:         "manual",
	}

	resp, err := s.rds.DescribeDBSnapshots(&options)
	req := testServer.WaitRequest()

	c.Assert(req.Form["Action"], DeepEquals, []string{"DescribeDBSnapshots"})
	c.Assert(req.Form["DBInstanceIdentifier"], DeepEquals, []string{"foobar"})
	c.Assert(req.Form["DBSnapshotIdentifier"], DeepEquals, []string{"baz"})
	c.Assert(req.Form["SnapshotType"], DeepEquals, []string{"manual"})
	c.Assert(err, IsNil)
	c.Assert(resp.RequestId, Equals, "b7769930-b98c-11d3-f272-7cd6cce12cc5")
	c.Assert(resp.DBSnapshots[0].OptionGroupName, Equals, "default:mysql-5-6")
	c.Assert(resp.DBSnapshots[0].Engine, Equals, "mysql")
	c.Assert(resp.DBSnapshots[0].SnapshotType, Equals, "manual")
}

func (s *S) Test_RestoreDBInstanceFromDBSnapshot(c *C) {
	testServer.Response(200, nil, RestoreDBInstanceFromDBSnapshotExample)

	options := rds.RestoreDBInstanceFromDBSnapshot{
		DBInstanceIdentifier: "foo",
		DBSnapshotIdentifier: "bar",
	}

	resp, err := s.rds.RestoreDBInstanceFromDBSnapshot(&options)
	req := testServer.WaitRequest()

	c.Assert(req.Form["Action"], DeepEquals, []string{"RestoreDBInstanceFromDBSnapshot"})
	c.Assert(req.Form["DBInstanceIdentifier"], DeepEquals, []string{"foo"})
	c.Assert(req.Form["DBSnapshotIdentifier"], DeepEquals, []string{"bar"})
	c.Assert(err, IsNil)
	c.Assert(resp.RequestId, Equals, "863fd73e-be2b-11d3-855b-576787000e19")
}
