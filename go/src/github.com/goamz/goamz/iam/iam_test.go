package iam_test

import (
	"strings"
	"testing"

	"github.com/goamz/goamz/aws"
	"github.com/goamz/goamz/iam"
	"github.com/goamz/goamz/testutil"
	"github.com/motain/gocheck"
)

func Test(t *testing.T) {
	gocheck.TestingT(t)
}

type S struct {
	iam *iam.IAM
}

var _ = gocheck.Suite(&S{})

var testServer = testutil.NewHTTPServer()

func (s *S) SetUpSuite(c *gocheck.C) {
	testServer.Start()
	auth := aws.Auth{AccessKey: "abc", SecretKey: "123"}
	s.iam = iam.NewWithClient(auth, aws.Region{IAMEndpoint: testServer.URL}, testutil.DefaultClient)
}

func (s *S) TearDownTest(c *gocheck.C) {
	testServer.Flush()
}

func (s *S) TestCreateUser(c *gocheck.C) {
	testServer.Response(200, nil, CreateUserExample)
	resp, err := s.iam.CreateUser("Bob", "/division_abc/subdivision_xyz/")
	values := testServer.WaitRequest().URL.Query()
	c.Assert(values.Get("Action"), gocheck.Equals, "CreateUser")
	c.Assert(values.Get("UserName"), gocheck.Equals, "Bob")
	c.Assert(values.Get("Path"), gocheck.Equals, "/division_abc/subdivision_xyz/")
	c.Assert(err, gocheck.IsNil)
	c.Assert(resp.RequestId, gocheck.Equals, "7a62c49f-347e-4fc4-9331-6e8eEXAMPLE")
	expected := iam.User{
		Path: "/division_abc/subdivision_xyz/",
		Name: "Bob",
		Id:   "AIDACKCEVSQ6C2EXAMPLE",
		Arn:  "arn:aws:iam::123456789012:user/division_abc/subdivision_xyz/Bob",
	}
	c.Assert(resp.User, gocheck.DeepEquals, expected)
}

func (s *S) TestCreateUserConflict(c *gocheck.C) {
	testServer.Response(409, nil, DuplicateUserExample)
	resp, err := s.iam.CreateUser("Bob", "/division_abc/subdivision_xyz/")
	testServer.WaitRequest()
	c.Assert(resp, gocheck.IsNil)
	c.Assert(err, gocheck.NotNil)
	e, ok := err.(*iam.Error)
	c.Assert(ok, gocheck.Equals, true)
	c.Assert(e.Message, gocheck.Equals, "User with name Bob already exists.")
	c.Assert(e.Code, gocheck.Equals, "EntityAlreadyExists")
}

func (s *S) TestGetUser(c *gocheck.C) {
	testServer.Response(200, nil, GetUserExample)
	resp, err := s.iam.GetUser("Bob")
	values := testServer.WaitRequest().URL.Query()
	c.Assert(values.Get("Action"), gocheck.Equals, "GetUser")
	c.Assert(values.Get("UserName"), gocheck.Equals, "Bob")
	c.Assert(err, gocheck.IsNil)
	c.Assert(resp.RequestId, gocheck.Equals, "7a62c49f-347e-4fc4-9331-6e8eEXAMPLE")
	expected := iam.User{
		Path: "/division_abc/subdivision_xyz/",
		Name: "Bob",
		Id:   "AIDACKCEVSQ6C2EXAMPLE",
		Arn:  "arn:aws:iam::123456789012:user/division_abc/subdivision_xyz/Bob",
	}
	c.Assert(resp.User, gocheck.DeepEquals, expected)
}

func (s *S) TestDeleteUser(c *gocheck.C) {
	testServer.Response(200, nil, RequestIdExample)
	resp, err := s.iam.DeleteUser("Bob")
	values := testServer.WaitRequest().URL.Query()
	c.Assert(values.Get("Action"), gocheck.Equals, "DeleteUser")
	c.Assert(values.Get("UserName"), gocheck.Equals, "Bob")
	c.Assert(err, gocheck.IsNil)
	c.Assert(resp.RequestId, gocheck.Equals, "7a62c49f-347e-4fc4-9331-6e8eEXAMPLE")
}

func (s *S) TestCreateGroup(c *gocheck.C) {
	testServer.Response(200, nil, CreateGroupExample)
	resp, err := s.iam.CreateGroup("Admins", "/admins/")
	values := testServer.WaitRequest().URL.Query()
	c.Assert(values.Get("Action"), gocheck.Equals, "CreateGroup")
	c.Assert(values.Get("GroupName"), gocheck.Equals, "Admins")
	c.Assert(values.Get("Path"), gocheck.Equals, "/admins/")
	c.Assert(err, gocheck.IsNil)
	c.Assert(resp.Group.Path, gocheck.Equals, "/admins/")
	c.Assert(resp.Group.Name, gocheck.Equals, "Admins")
	c.Assert(resp.Group.Id, gocheck.Equals, "AGPACKCEVSQ6C2EXAMPLE")
	c.Assert(resp.RequestId, gocheck.Equals, "7a62c49f-347e-4fc4-9331-6e8eEXAMPLE")
}

func (s *S) TestCreateGroupWithoutPath(c *gocheck.C) {
	testServer.Response(200, nil, CreateGroupExample)
	_, err := s.iam.CreateGroup("Managers", "")
	values := testServer.WaitRequest().URL.Query()
	c.Assert(values.Get("Action"), gocheck.Equals, "CreateGroup")
	c.Assert(err, gocheck.IsNil)
	_, ok := map[string][]string(values)["Path"]
	c.Assert(ok, gocheck.Equals, false)
}

func (s *S) TestDeleteGroup(c *gocheck.C) {
	testServer.Response(200, nil, RequestIdExample)
	resp, err := s.iam.DeleteGroup("Admins")
	values := testServer.WaitRequest().URL.Query()
	c.Assert(values.Get("Action"), gocheck.Equals, "DeleteGroup")
	c.Assert(values.Get("GroupName"), gocheck.Equals, "Admins")
	c.Assert(err, gocheck.IsNil)
	c.Assert(resp.RequestId, gocheck.Equals, "7a62c49f-347e-4fc4-9331-6e8eEXAMPLE")
}

func (s *S) TestListGroups(c *gocheck.C) {
	testServer.Response(200, nil, ListGroupsExample)
	resp, err := s.iam.Groups("/division_abc/")
	values := testServer.WaitRequest().URL.Query()
	c.Assert(values.Get("Action"), gocheck.Equals, "ListGroups")
	c.Assert(values.Get("PathPrefix"), gocheck.Equals, "/division_abc/")
	c.Assert(err, gocheck.IsNil)
	c.Assert(resp.RequestId, gocheck.Equals, "7a62c49f-347e-4fc4-9331-6e8eEXAMPLE")
	expected := []iam.Group{
		{
			Path: "/division_abc/subdivision_xyz/",
			Name: "Admins",
			Id:   "AGPACKCEVSQ6C2EXAMPLE",
			Arn:  "arn:aws:iam::123456789012:group/Admins",
		},
		{
			Path: "/division_abc/subdivision_xyz/product_1234/engineering/",
			Name: "Test",
			Id:   "AGP2MAB8DPLSRHEXAMPLE",
			Arn:  "arn:aws:iam::123456789012:group/division_abc/subdivision_xyz/product_1234/engineering/Test",
		},
		{
			Path: "/division_abc/subdivision_xyz/product_1234/",
			Name: "Managers",
			Id:   "AGPIODR4TAW7CSEXAMPLE",
			Arn:  "arn:aws:iam::123456789012:group/division_abc/subdivision_xyz/product_1234/Managers",
		},
	}
	c.Assert(resp.Groups, gocheck.DeepEquals, expected)
}

func (s *S) TestListGroupsWithoutPathPrefix(c *gocheck.C) {
	testServer.Response(200, nil, ListGroupsExample)
	_, err := s.iam.Groups("")
	values := testServer.WaitRequest().URL.Query()
	c.Assert(values.Get("Action"), gocheck.Equals, "ListGroups")
	c.Assert(err, gocheck.IsNil)
	_, ok := map[string][]string(values)["PathPrefix"]
	c.Assert(ok, gocheck.Equals, false)
}

func (s *S) TestCreateAccessKey(c *gocheck.C) {
	testServer.Response(200, nil, CreateAccessKeyExample)
	resp, err := s.iam.CreateAccessKey("Bob")
	values := testServer.WaitRequest().URL.Query()
	c.Assert(values.Get("Action"), gocheck.Equals, "CreateAccessKey")
	c.Assert(values.Get("UserName"), gocheck.Equals, "Bob")
	c.Assert(err, gocheck.IsNil)
	c.Assert(resp.AccessKey.UserName, gocheck.Equals, "Bob")
	c.Assert(resp.AccessKey.Id, gocheck.Equals, "AKIAIOSFODNN7EXAMPLE")
	c.Assert(resp.AccessKey.Secret, gocheck.Equals, "wJalrXUtnFEMI/K7MDENG/bPxRfiCYzEXAMPLEKEY")
	c.Assert(resp.AccessKey.Status, gocheck.Equals, "Active")
}

func (s *S) TestDeleteAccessKey(c *gocheck.C) {
	testServer.Response(200, nil, RequestIdExample)
	resp, err := s.iam.DeleteAccessKey("ysa8hasdhasdsi", "Bob")
	values := testServer.WaitRequest().URL.Query()
	c.Assert(values.Get("Action"), gocheck.Equals, "DeleteAccessKey")
	c.Assert(values.Get("AccessKeyId"), gocheck.Equals, "ysa8hasdhasdsi")
	c.Assert(values.Get("UserName"), gocheck.Equals, "Bob")
	c.Assert(err, gocheck.IsNil)
	c.Assert(resp.RequestId, gocheck.Equals, "7a62c49f-347e-4fc4-9331-6e8eEXAMPLE")
}

func (s *S) TestDeleteAccessKeyBlankUserName(c *gocheck.C) {
	testServer.Response(200, nil, RequestIdExample)
	_, err := s.iam.DeleteAccessKey("ysa8hasdhasdsi", "")
	c.Assert(err, gocheck.IsNil)
	values := testServer.WaitRequest().URL.Query()
	c.Assert(values.Get("Action"), gocheck.Equals, "DeleteAccessKey")
	c.Assert(values.Get("AccessKeyId"), gocheck.Equals, "ysa8hasdhasdsi")
	_, ok := map[string][]string(values)["UserName"]
	c.Assert(ok, gocheck.Equals, false)
}

func (s *S) TestAccessKeys(c *gocheck.C) {
	testServer.Response(200, nil, ListAccessKeyExample)
	resp, err := s.iam.AccessKeys("Bob")
	values := testServer.WaitRequest().URL.Query()
	c.Assert(values.Get("Action"), gocheck.Equals, "ListAccessKeys")
	c.Assert(values.Get("UserName"), gocheck.Equals, "Bob")
	c.Assert(err, gocheck.IsNil)
	c.Assert(resp.RequestId, gocheck.Equals, "7a62c49f-347e-4fc4-9331-6e8eEXAMPLE")
	c.Assert(resp.AccessKeys, gocheck.HasLen, 2)
	c.Assert(resp.AccessKeys[0].Id, gocheck.Equals, "AKIAIOSFODNN7EXAMPLE")
	c.Assert(resp.AccessKeys[0].UserName, gocheck.Equals, "Bob")
	c.Assert(resp.AccessKeys[0].Status, gocheck.Equals, "Active")
	c.Assert(resp.AccessKeys[1].Id, gocheck.Equals, "AKIAI44QH8DHBEXAMPLE")
	c.Assert(resp.AccessKeys[1].UserName, gocheck.Equals, "Bob")
	c.Assert(resp.AccessKeys[1].Status, gocheck.Equals, "Inactive")
}

func (s *S) TestAccessKeysBlankUserName(c *gocheck.C) {
	testServer.Response(200, nil, ListAccessKeyExample)
	_, err := s.iam.AccessKeys("")
	c.Assert(err, gocheck.IsNil)
	values := testServer.WaitRequest().URL.Query()
	c.Assert(values.Get("Action"), gocheck.Equals, "ListAccessKeys")
	_, ok := map[string][]string(values)["UserName"]
	c.Assert(ok, gocheck.Equals, false)
}

func (s *S) TestGetUserPolicy(c *gocheck.C) {
	testServer.Response(200, nil, GetUserPolicyExample)
	resp, err := s.iam.GetUserPolicy("Bob", "AllAccessPolicy")
	values := testServer.WaitRequest().URL.Query()
	c.Assert(values.Get("Action"), gocheck.Equals, "GetUserPolicy")
	c.Assert(values.Get("UserName"), gocheck.Equals, "Bob")
	c.Assert(values.Get("PolicyName"), gocheck.Equals, "AllAccessPolicy")
	c.Assert(err, gocheck.IsNil)
	c.Assert(resp.Policy.UserName, gocheck.Equals, "Bob")
	c.Assert(resp.Policy.Name, gocheck.Equals, "AllAccessPolicy")
	c.Assert(strings.TrimSpace(resp.Policy.Document), gocheck.Equals, `{"Statement":[{"Effect":"Allow","Action":"*","Resource":"*"}]}`)
	c.Assert(resp.RequestId, gocheck.Equals, "7a62c49f-347e-4fc4-9331-6e8eEXAMPLE")
}

func (s *S) TestPutUserPolicy(c *gocheck.C) {
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
	testServer.Response(200, nil, RequestIdExample)
	resp, err := s.iam.PutUserPolicy("Bob", "AllAccessPolicy", document)
	req := testServer.WaitRequest()
	c.Assert(req.Method, gocheck.Equals, "POST")
	c.Assert(req.FormValue("Action"), gocheck.Equals, "PutUserPolicy")
	c.Assert(req.FormValue("PolicyName"), gocheck.Equals, "AllAccessPolicy")
	c.Assert(req.FormValue("UserName"), gocheck.Equals, "Bob")
	c.Assert(req.FormValue("PolicyDocument"), gocheck.Equals, document)
	c.Assert(req.FormValue("Version"), gocheck.Equals, "2010-05-08")
	c.Assert(err, gocheck.IsNil)
	c.Assert(resp.RequestId, gocheck.Equals, "7a62c49f-347e-4fc4-9331-6e8eEXAMPLE")
}

func (s *S) TestDeleteUserPolicy(c *gocheck.C) {
	testServer.Response(200, nil, RequestIdExample)
	resp, err := s.iam.DeleteUserPolicy("Bob", "AllAccessPolicy")
	values := testServer.WaitRequest().URL.Query()
	c.Assert(values.Get("Action"), gocheck.Equals, "DeleteUserPolicy")
	c.Assert(values.Get("PolicyName"), gocheck.Equals, "AllAccessPolicy")
	c.Assert(values.Get("UserName"), gocheck.Equals, "Bob")
	c.Assert(err, gocheck.IsNil)
	c.Assert(resp.RequestId, gocheck.Equals, "7a62c49f-347e-4fc4-9331-6e8eEXAMPLE")
}

func (s *S) TestAddUserToGroup(c *gocheck.C) {
	testServer.Response(200, nil, AddUserToGroupExample)
	resp, err := s.iam.AddUserToGroup("admin1", "Admins")
	values := testServer.WaitRequest().URL.Query()
	c.Assert(values.Get("Action"), gocheck.Equals, "AddUserToGroup")
	c.Assert(values.Get("GroupName"), gocheck.Equals, "Admins")
	c.Assert(values.Get("UserName"), gocheck.Equals, "admin1")
	c.Assert(err, gocheck.IsNil)
	c.Assert(resp.RequestId, gocheck.Equals, "7a62c49f-347e-4fc4-9331-6e8eEXAMPLE")
}

func (s *S) TestListAccountAliases(c *gocheck.C) {
	testServer.Response(200, nil, ListAccountAliasesExample)
	resp, err := s.iam.ListAccountAliases()
	values := testServer.WaitRequest().URL.Query()
	c.Assert(values.Get("Action"), gocheck.Equals, "ListAccountAliases")
	c.Assert(err, gocheck.IsNil)
	c.Assert(resp.AccountAliases[0], gocheck.Equals, "foocorporation")
	c.Assert(resp.RequestId, gocheck.Equals, "c5a076e9-f1b0-11df-8fbe-45274EXAMPLE")
}

func (s *S) TestCreateAccountAlias(c *gocheck.C) {
	testServer.Response(200, nil, CreateAccountAliasExample)
	resp, err := s.iam.CreateAccountAlias("foobaz")
	values := testServer.WaitRequest().URL.Query()
	c.Assert(values.Get("Action"), gocheck.Equals, "CreateAccountAlias")
	c.Assert(values.Get("AccountAlias"), gocheck.Equals, "foobaz")
	c.Assert(err, gocheck.IsNil)
	c.Assert(resp.RequestId, gocheck.Equals, "36b5db08-f1b0-11df-8fbe-45274EXAMPLE")
}

func (s *S) TestDeleteAccountAlias(c *gocheck.C) {
	testServer.Response(200, nil, DeleteAccountAliasExample)
	resp, err := s.iam.DeleteAccountAlias("foobaz")
	values := testServer.WaitRequest().URL.Query()
	c.Assert(values.Get("Action"), gocheck.Equals, "DeleteAccountAlias")
	c.Assert(values.Get("AccountAlias"), gocheck.Equals, "foobaz")
	c.Assert(err, gocheck.IsNil)
	c.Assert(resp.RequestId, gocheck.Equals, "7a62c49f-347e-4fc4-9331-6e8eEXAMPLE")
}
