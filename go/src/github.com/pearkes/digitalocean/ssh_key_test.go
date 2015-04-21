package digitalocean

import (
	"testing"

	. "github.com/motain/gocheck"
)

func TestSSHKey(t *testing.T) {
	TestingT(t)
}

func (s *S) Test_CreateSSHKey(c *C) {
	testServer.Response(202, nil, sshKeyExample)

	opts := CreateSSHKey{
		Name:      "A",
		PublicKey: "abcd",
	}

	id, err := s.client.CreateSSHKey(&opts)

	_ = testServer.WaitRequest()

	c.Assert(err, IsNil)
	c.Assert(id, Equals, "16")
}

func (s *S) Test_RetrieveSSHKey(c *C) {
	testServer.Response(200, nil, sshKeyExample)

	sshKey, err := s.client.RetrieveSSHKey("16")

	_ = testServer.WaitRequest()

	c.Assert(err, IsNil)
	c.Assert(sshKey.StringId(), Equals, "16")
	c.Assert(sshKey.Fingerprint, Equals, "AAAA")
	c.Assert(sshKey.Name, Equals, "A")
	c.Assert(sshKey.PublicKey, Equals, "abcd")
}

func (s *S) Test_RenameSSHKey(c *C) {
	testServer.Response(200, nil, sshKeyExample)

	err := s.client.RenameSSHKey("16", "pepe")

	_ = testServer.WaitRequest()

	c.Assert(err, IsNil)
}

var sshKeyExample = `{
  "ssh_key": {
    "id": 16,
    "fingerprint": "AAAA",
    "name": "A",
    "public_key": "abcd"
  }
}`
