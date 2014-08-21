package aws_test

import (
	"github.com/goamz/goamz/aws"
	"github.com/motain/gocheck"
	"os"
	"strings"
	"testing"
	"time"
)

func Test(t *testing.T) {
	gocheck.TestingT(t)
}

var _ = gocheck.Suite(&S{})

type S struct {
	environ []string
}

func (s *S) SetUpSuite(c *gocheck.C) {
	s.environ = os.Environ()
}

func (s *S) TearDownTest(c *gocheck.C) {
	os.Clearenv()
	for _, kv := range s.environ {
		l := strings.SplitN(kv, "=", 2)
		os.Setenv(l[0], l[1])
	}
}

func (s *S) TestEnvAuthNoSecret(c *gocheck.C) {
	os.Clearenv()
	_, err := aws.EnvAuth()
	c.Assert(err, gocheck.ErrorMatches, "AWS_SECRET_ACCESS_KEY or AWS_SECRET_KEY not found in environment")
}

func (s *S) TestEnvAuthNoAccess(c *gocheck.C) {
	os.Clearenv()
	os.Setenv("AWS_SECRET_ACCESS_KEY", "foo")
	_, err := aws.EnvAuth()
	c.Assert(err, gocheck.ErrorMatches, "AWS_ACCESS_KEY_ID or AWS_ACCESS_KEY not found in environment")
}

func (s *S) TestEnvAuth(c *gocheck.C) {
	os.Clearenv()
	os.Setenv("AWS_SECRET_ACCESS_KEY", "secret")
	os.Setenv("AWS_ACCESS_KEY_ID", "access")
	auth, err := aws.EnvAuth()
	c.Assert(err, gocheck.IsNil)
	c.Assert(auth, gocheck.Equals, aws.Auth{SecretKey: "secret", AccessKey: "access"})
}

func (s *S) TestEnvAuthAlt(c *gocheck.C) {
	os.Clearenv()
	os.Setenv("AWS_SECRET_KEY", "secret")
	os.Setenv("AWS_ACCESS_KEY", "access")
	auth, err := aws.EnvAuth()
	c.Assert(err, gocheck.IsNil)
	c.Assert(auth, gocheck.Equals, aws.Auth{SecretKey: "secret", AccessKey: "access"})
}

func (s *S) TestGetAuthStatic(c *gocheck.C) {
	exptdate := time.Now().Add(time.Hour)
	auth, err := aws.GetAuth("access", "secret", "token", exptdate)
	c.Assert(err, gocheck.IsNil)
	c.Assert(auth.AccessKey, gocheck.Equals, "access")
	c.Assert(auth.SecretKey, gocheck.Equals, "secret")
	c.Assert(auth.Token(), gocheck.Equals, "token")
	c.Assert(auth.Expiration(), gocheck.Equals, exptdate)
}

func (s *S) TestGetAuthEnv(c *gocheck.C) {
	os.Clearenv()
	os.Setenv("AWS_SECRET_ACCESS_KEY", "secret")
	os.Setenv("AWS_ACCESS_KEY_ID", "access")
	auth, err := aws.GetAuth("", "", "", time.Time{})
	c.Assert(err, gocheck.IsNil)
	c.Assert(auth, gocheck.Equals, aws.Auth{SecretKey: "secret", AccessKey: "access"})
}

func (s *S) TestEncode(c *gocheck.C) {
	c.Assert(aws.Encode("foo"), gocheck.Equals, "foo")
	c.Assert(aws.Encode("/"), gocheck.Equals, "%2F")
}

func (s *S) TestRegionsAreNamed(c *gocheck.C) {
	for n, r := range aws.Regions {
		c.Assert(n, gocheck.Equals, r.Name)
	}
}
