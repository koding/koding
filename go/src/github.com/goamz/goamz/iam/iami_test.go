package iam_test

import (
	"github.com/goamz/goamz/aws"
	"github.com/goamz/goamz/iam"
	"github.com/goamz/goamz/testutil"
	"github.com/motain/gocheck"
	"net/url"
)

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

func (s *AmazonClientSuite) SetUpSuite(c *gocheck.C) {
	if !testutil.Amazon {
		c.Skip("AmazonClientSuite tests not enabled")
	}
	s.srv.SetUp(c)
	s.iam = iam.New(s.srv.auth, aws.USEast)
}

// ClientTests defines integration tests designed to test the client.
// It is not used as a test suite in itself, but embedded within
// another type.
type ClientTests struct {
	iam *iam.IAM
}

func (s *ClientTests) TestCreateAndDeleteUser(c *gocheck.C) {
	createResp, err := s.iam.CreateUser("gopher", "/gopher/")
	c.Assert(err, gocheck.IsNil)
	getResp, err := s.iam.GetUser("gopher")
	c.Assert(err, gocheck.IsNil)
	c.Assert(createResp.User, gocheck.DeepEquals, getResp.User)
	_, err = s.iam.DeleteUser("gopher")
	c.Assert(err, gocheck.IsNil)
}

func (s *ClientTests) TestCreateUserError(c *gocheck.C) {
	_, err := s.iam.CreateUser("gopher", "/gopher/")
	c.Assert(err, gocheck.IsNil)
	defer s.iam.DeleteUser("gopher")
	_, err = s.iam.CreateUser("gopher", "/")
	iamErr, ok := err.(*iam.Error)
	c.Assert(ok, gocheck.Equals, true)
	c.Assert(iamErr.StatusCode, gocheck.Equals, 409)
	c.Assert(iamErr.Code, gocheck.Equals, "EntityAlreadyExists")
	c.Assert(iamErr.Message, gocheck.Equals, "User with name gopher already exists.")
}

func (s *ClientTests) TestDeleteUserError(c *gocheck.C) {
	_, err := s.iam.DeleteUser("gopher")
	iamErr, ok := err.(*iam.Error)
	c.Assert(ok, gocheck.Equals, true)
	c.Assert(iamErr.StatusCode, gocheck.Equals, 404)
	c.Assert(iamErr.Code, gocheck.Equals, "NoSuchEntity")
	c.Assert(iamErr.Message, gocheck.Equals, "The user with name gopher cannot be found.")
}

func (s *ClientTests) TestGetUserError(c *gocheck.C) {
	_, err := s.iam.GetUser("gopher")
	iamErr, ok := err.(*iam.Error)
	c.Assert(ok, gocheck.Equals, true)
	c.Assert(iamErr.StatusCode, gocheck.Equals, 404)
	c.Assert(iamErr.Code, gocheck.Equals, "NoSuchEntity")
	c.Assert(iamErr.Message, gocheck.Equals, "The user with name gopher cannot be found.")
}

func (s *ClientTests) TestCreateListAndDeleteAccessKey(c *gocheck.C) {
	createUserResp, err := s.iam.CreateUser("gopher", "/gopher/")
	c.Assert(err, gocheck.IsNil)
	defer s.iam.DeleteUser(createUserResp.User.Name)
	createKeyResp, err := s.iam.CreateAccessKey(createUserResp.User.Name)
	c.Assert(err, gocheck.IsNil)
	listKeyResp, err := s.iam.AccessKeys(createUserResp.User.Name)
	c.Assert(err, gocheck.IsNil)
	c.Assert(listKeyResp.AccessKeys, gocheck.HasLen, 1)
	createKeyResp.AccessKey.Secret = ""
	c.Assert(listKeyResp.AccessKeys[0], gocheck.DeepEquals, createKeyResp.AccessKey)
	_, err = s.iam.DeleteAccessKey(createKeyResp.AccessKey.Id, createUserResp.User.Name)
	c.Assert(err, gocheck.IsNil)
}

func (s *ClientTests) TestCreateAccessKeyError(c *gocheck.C) {
	_, err := s.iam.CreateAccessKey("unknowngopher")
	c.Assert(err, gocheck.NotNil)
	iamErr, ok := err.(*iam.Error)
	c.Assert(ok, gocheck.Equals, true)
	c.Assert(iamErr.StatusCode, gocheck.Equals, 404)
	c.Assert(iamErr.Code, gocheck.Equals, "NoSuchEntity")
	c.Assert(iamErr.Message, gocheck.Equals, "The user with name unknowngopher cannot be found.")
}

func (s *ClientTests) TestListAccessKeysUserNotFound(c *gocheck.C) {
	_, err := s.iam.AccessKeys("unknowngopher")
	c.Assert(err, gocheck.NotNil)
	iamErr, ok := err.(*iam.Error)
	c.Assert(ok, gocheck.Equals, true)
	c.Assert(iamErr.StatusCode, gocheck.Equals, 404)
	c.Assert(iamErr.Code, gocheck.Equals, "NoSuchEntity")
	c.Assert(iamErr.Message, gocheck.Equals, "The user with name unknowngopher cannot be found.")
}

func (s *ClientTests) TestListAccessKeysUserWithoutKeys(c *gocheck.C) {
	createUserResp, err := s.iam.CreateUser("gopher", "/")
	c.Assert(err, gocheck.IsNil)
	defer s.iam.DeleteUser(createUserResp.User.Name)
	resp, err := s.iam.AccessKeys(createUserResp.User.Name)
	c.Assert(err, gocheck.IsNil)
	c.Assert(resp.AccessKeys, gocheck.HasLen, 0)
}

func (s *ClientTests) TestCreateListAndDeleteGroup(c *gocheck.C) {
	cResp1, err := s.iam.CreateGroup("Finances", "/finances/")
	c.Assert(err, gocheck.IsNil)
	cResp2, err := s.iam.CreateGroup("DevelopmentManagers", "/development/managers/")
	c.Assert(err, gocheck.IsNil)
	lResp, err := s.iam.Groups("/development/")
	c.Assert(err, gocheck.IsNil)
	c.Assert(lResp.Groups, gocheck.HasLen, 1)
	c.Assert(cResp2.Group, gocheck.DeepEquals, lResp.Groups[0])
	lResp, err = s.iam.Groups("")
	c.Assert(err, gocheck.IsNil)
	c.Assert(lResp.Groups, gocheck.HasLen, 2)
	if lResp.Groups[0].Name == cResp1.Group.Name {
		c.Assert([]iam.Group{cResp1.Group, cResp2.Group}, gocheck.DeepEquals, lResp.Groups)
	} else {
		c.Assert([]iam.Group{cResp2.Group, cResp1.Group}, gocheck.DeepEquals, lResp.Groups)
	}
	_, err = s.iam.DeleteGroup("DevelopmentManagers")
	c.Assert(err, gocheck.IsNil)
	lResp, err = s.iam.Groups("/development/")
	c.Assert(err, gocheck.IsNil)
	c.Assert(lResp.Groups, gocheck.HasLen, 0)
	_, err = s.iam.DeleteGroup("Finances")
	c.Assert(err, gocheck.IsNil)
}

func (s *ClientTests) TestCreateGroupError(c *gocheck.C) {
	_, err := s.iam.CreateGroup("Finances", "/finances/")
	c.Assert(err, gocheck.IsNil)
	defer s.iam.DeleteGroup("Finances")
	_, err = s.iam.CreateGroup("Finances", "/something-else/")
	iamErr, ok := err.(*iam.Error)
	c.Assert(ok, gocheck.Equals, true)
	c.Assert(iamErr.StatusCode, gocheck.Equals, 409)
	c.Assert(iamErr.Code, gocheck.Equals, "EntityAlreadyExists")
	c.Assert(iamErr.Message, gocheck.Equals, "Group with name Finances already exists.")
}

func (s *ClientTests) TestDeleteGroupError(c *gocheck.C) {
	_, err := s.iam.DeleteGroup("Finances")
	iamErr, ok := err.(*iam.Error)
	c.Assert(ok, gocheck.Equals, true)
	c.Assert(iamErr.StatusCode, gocheck.Equals, 404)
	c.Assert(iamErr.Code, gocheck.Equals, "NoSuchEntity")
	c.Assert(iamErr.Message, gocheck.Equals, "The group with name Finances cannot be found.")
}

func (s *ClientTests) TestPutGetAndDeleteUserPolicy(c *gocheck.C) {
	userResp, err := s.iam.CreateUser("gopher", "/gopher/")
	c.Assert(err, gocheck.IsNil)
	defer s.iam.DeleteUser(userResp.User.Name)
	document := `{
		"Statement": [
		{
			"Action": [
				"s3:*"
			],
			"Effect": "Allow",
			"Resource": [
				"arn:aws:s3:::8shsns19s90ajahadsj/*",
				"arn:aws:s3:::8shsns19s90ajahadsj"
			]
		}]
	}`
	_, err = s.iam.PutUserPolicy(userResp.User.Name, "EverythingS3", document)
	c.Assert(err, gocheck.IsNil)
	resp, err := s.iam.GetUserPolicy(userResp.User.Name, "EverythingS3")
	c.Assert(err, gocheck.IsNil)
	c.Assert(resp.Policy.Name, gocheck.Equals, "EverythingS3")
	c.Assert(resp.Policy.UserName, gocheck.Equals, userResp.User.Name)
	gotDocument, err := url.QueryUnescape(resp.Policy.Document)
	c.Assert(err, gocheck.IsNil)
	c.Assert(gotDocument, gocheck.Equals, document)
	_, err = s.iam.DeleteUserPolicy(userResp.User.Name, "EverythingS3")
	c.Assert(err, gocheck.IsNil)
	_, err = s.iam.GetUserPolicy(userResp.User.Name, "EverythingS3")
	c.Assert(err, gocheck.NotNil)
}
