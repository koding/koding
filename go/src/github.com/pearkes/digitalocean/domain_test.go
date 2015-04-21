package digitalocean

import (
	"testing"

	. "github.com/motain/gocheck"
)

func TestDomain(t *testing.T) {
	TestingT(t)
}

func (s *S) Test_CreateDomain(c *C) {
	testServer.Response(202, nil, domainExample)

	opts := CreateDomain{
		Name: "example.com",
	}

	id, err := s.client.CreateDomain(&opts)

	_ = testServer.WaitRequest()

	c.Assert(err, IsNil)
	c.Assert(id, Equals, "example.com")
}

func (s *S) Test_RetrieveDomain(c *C) {
	testServer.Response(200, nil, domainExample)

	domain, err := s.client.RetrieveDomain("example.com")

	_ = testServer.WaitRequest()

	c.Assert(err, IsNil)
	c.Assert(domain.Name, Equals, "example.com")
	c.Assert(domain.ZoneFile, Equals, "")
}

func (s *S) Test_DestroyDomain(c *C) {
	testServer.Response(204, nil, "")

	err := s.client.DestroyDomain("example.com")

	_ = testServer.WaitRequest()

	c.Assert(err, IsNil)
}

var domainErrorExample = `{
  "id": "unprocessable_entity",
  "message": "Ip address can't be blank."
}`

var domainExample = `{
  "domain": {
    "name": "example.com",
    "ttl": 1800,
    "zone_file": ""
  }
}`
