package s3_test

import (
	"github.com/goamz/goamz/aws"
	"github.com/goamz/goamz/s3"
	"github.com/goamz/goamz/s3/s3test"
	"github.com/motain/gocheck"
)

type LocalServer struct {
	auth   aws.Auth
	region aws.Region
	srv    *s3test.Server
	config *s3test.Config
}

func (s *LocalServer) SetUp(c *gocheck.C) {
	srv, err := s3test.NewServer(s.config)
	c.Assert(err, gocheck.IsNil)
	c.Assert(srv, gocheck.NotNil)

	s.srv = srv
	s.region = aws.Region{
		Name:                 "faux-region-1",
		S3Endpoint:           srv.URL(),
		S3LocationConstraint: true, // s3test server requires a LocationConstraint
	}
}

// LocalServerSuite defines tests that will run
// against the local s3test server. It includes
// selected tests from ClientTests;
// when the s3test functionality is sufficient, it should
// include all of them, and ClientTests can be simply embedded.
type LocalServerSuite struct {
	srv         LocalServer
	clientTests ClientTests
}

var (
	// run tests twice, once in us-east-1 mode, once not.
	_ = gocheck.Suite(&LocalServerSuite{})
	_ = gocheck.Suite(&LocalServerSuite{
		srv: LocalServer{
			config: &s3test.Config{
				Send409Conflict: true,
			},
		},
	})
)

func (s *LocalServerSuite) SetUpSuite(c *gocheck.C) {
	s.srv.SetUp(c)
	s.clientTests.s3 = s3.New(s.srv.auth, s.srv.region)

	// TODO Sadly the fake server ignores auth completely right now. :-(
	s.clientTests.authIsBroken = true
	s.clientTests.Cleanup()
}

func (s *LocalServerSuite) TearDownTest(c *gocheck.C) {
	s.clientTests.Cleanup()
}

func (s *LocalServerSuite) TestBasicFunctionality(c *gocheck.C) {
	s.clientTests.TestBasicFunctionality(c)
}

func (s *LocalServerSuite) TestGetNotFound(c *gocheck.C) {
	s.clientTests.TestGetNotFound(c)
}

func (s *LocalServerSuite) TestBucketList(c *gocheck.C) {
	s.clientTests.TestBucketList(c)
}

func (s *LocalServerSuite) TestDoublePutBucket(c *gocheck.C) {
	s.clientTests.TestDoublePutBucket(c)
}
