package main

import (
	. "launchpad.net/gocheck"
	"log"
)

func init() {
	log.SetPrefix("Externals test")
}

func (s *MySuite) TestGettingClientsBasedOnTokenType(c *C) {
	token := githubTokenFixture()
	clients := getClientsForService(token)

	c.Check(clients, NotNil)
}
