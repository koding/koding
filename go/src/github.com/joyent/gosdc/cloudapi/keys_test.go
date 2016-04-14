package cloudapi_test

import (
	gc "launchpad.net/gocheck"

	"github.com/joyent/gosdc/cloudapi"
)

func (s *LocalTests) TestCreateKey(c *gc.C) {
	s.createKey(c)
	s.deleteKey(c)
}

func (s *LocalTests) TestListKeys(c *gc.C) {
	s.createKey(c)
	defer s.deleteKey(c)

	keys, err := s.testClient.ListKeys()
	c.Assert(err, gc.IsNil)
	c.Assert(keys, gc.NotNil)
	fakeKey := cloudapi.Key{Name: "fake-key", Fingerprint: "", Key: testKey}
	for _, k := range keys {
		if c.Check(k, gc.DeepEquals, fakeKey) {
			c.SucceedNow()
		}
	}
	c.Fatalf("Obtained keys [%s] do not contain test key [%s]", keys, fakeKey)
}

func (s *LocalTests) TestGetKey(c *gc.C) {
	s.createKey(c)
	defer s.deleteKey(c)

	key, err := s.testClient.GetKey("fake-key")
	c.Assert(err, gc.IsNil)
	c.Assert(key, gc.NotNil)
	c.Assert(key, gc.DeepEquals, &cloudapi.Key{Name: "fake-key", Fingerprint: "", Key: testKey})
}

func (s *LocalTests) TestDeleteKey(c *gc.C) {
	s.createKey(c)

	s.deleteKey(c)
}
