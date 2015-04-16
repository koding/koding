package digitalocean

import (
	"testing"

	. "github.com/motain/gocheck"
)

func TestRecord(t *testing.T) {
	TestingT(t)
}

func (s *S) Test_CreateRecord(c *C) {
	testServer.Response(202, nil, recordExample)

	opts := CreateRecord{
		Type: "A",
		Name: "foobar",
		Data: "10.0.0.1",
	}

	id, err := s.client.CreateRecord("example.com", &opts)

	_ = testServer.WaitRequest()

	c.Assert(err, IsNil)
	c.Assert(id, Equals, "16")
}

func (s *S) Test_RetrieveRecord(c *C) {
	testServer.Response(200, nil, recordExample)

	record, err := s.client.RetrieveRecord("example.com", "25")

	_ = testServer.WaitRequest()

	c.Assert(err, IsNil)
	c.Assert(record.Name, Equals, "subdomain")
	c.Assert(record.StringId(), Equals, "16")
	c.Assert(record.StringPort(), Equals, "0")
}

func (s *S) Test_DestroyRecord(c *C) {
	testServer.Response(204, nil, "")

	err := s.client.DestroyRecord("example.com", "25")

	_ = testServer.WaitRequest()

	c.Assert(err, IsNil)
}

func (s *S) Test_UpdateRecord(c *C) {
	testServer.Response(204, nil, "")

	opts := UpdateRecord{
		Name: "foobaz",
	}

	err := s.client.UpdateRecord("example.com", "25", &opts)

	_ = testServer.WaitRequest()

	c.Assert(err, IsNil)
}

var recordErrorExample = `{
  "id": "unprocessable_entity",
  "message": "Type can't be blank."
}`

var recordExample = `{
  "domain_record": {
    "id": 16,
    "type": "AAAA",
    "name": "subdomain",
    "data": "2001:db8::ff00:42:8329",
    "priority": null,
    "port": null,
    "weight": null
  }
}`
