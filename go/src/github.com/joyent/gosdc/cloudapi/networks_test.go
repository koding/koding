package cloudapi_test

import (
	gc "launchpad.net/gocheck"

	"github.com/joyent/gosdc/cloudapi"
)

func (s *LocalTests) TestListNetworks(c *gc.C) {
	nets, err := s.testClient.ListNetworks()
	c.Assert(err, gc.IsNil)
	c.Assert(nets, gc.NotNil)
}

func (s *LocalTests) TestGetNetwork(c *gc.C) {
	net, err := s.testClient.GetNetwork(localNetworkID)
	c.Assert(err, gc.IsNil)
	c.Assert(net, gc.NotNil)
	c.Assert(net, gc.DeepEquals, &cloudapi.Network{
		Id:          localNetworkID,
		Name:        "Test-Joyent-Public",
		Public:      true,
		Description: "",
	})
}
