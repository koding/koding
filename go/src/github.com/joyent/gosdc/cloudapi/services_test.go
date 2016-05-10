package cloudapi_test

import (
	gc "launchpad.net/gocheck"
)

func (s *LocalTests) TestListServices(c *gc.C) {
	services, err := s.testClient.ListServices()
	c.Assert(err, gc.IsNil)
	c.Assert(services, gc.NotNil)
}
