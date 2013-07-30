package main

import (
	. "launchpad.net/gocheck"
	"log"
)

func init() {
	log.SetPrefix("Externals test: ")
}

func (s *MySuite) TestUsingFakeMongoDocumentDBAdapter(c *C) {
	// this line will fail when FakeMongo doesn't satisfy DocumentDB interface
	mongo = &FakeMongo{}
	user, exists := mongo.GetUser("4f14f9d8519ab4c62e000033")

	c.Check(exists, Equals, true)
	c.Check(user["_id"], Equals, "4f14f9d8519ab4c62e000033")
}

func (s *MySuite) TestGettingTagFromMongo(c *C) {
	mongo = &Mongo{}
	tag, exists := mongo.GetTagByName("status update", "github")
	c.Assert(tag, NotNil)
	c.Check(exists, Equals, true)
}
