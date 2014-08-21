package iam_test

import (
	"github.com/goamz/goamz/aws"
	"github.com/goamz/goamz/iam"
	"github.com/goamz/goamz/iam/iamtest"
	"github.com/motain/gocheck"
)

// LocalServer represents a local ec2test fake server.
type LocalServer struct {
	auth   aws.Auth
	region aws.Region
	srv    *iamtest.Server
}

func (s *LocalServer) SetUp(c *gocheck.C) {
	srv, err := iamtest.NewServer()
	c.Assert(err, gocheck.IsNil)
	c.Assert(srv, gocheck.NotNil)

	s.srv = srv
	s.region = aws.Region{IAMEndpoint: srv.URL()}
}

// LocalServerSuite defines tests that will run
// against the local iamtest server. It includes
// tests from ClientTests.
type LocalServerSuite struct {
	srv LocalServer
	ClientTests
}

var _ = gocheck.Suite(&LocalServerSuite{})

func (s *LocalServerSuite) SetUpSuite(c *gocheck.C) {
	s.srv.SetUp(c)
	s.ClientTests.iam = iam.New(s.srv.auth, s.srv.region)
}
