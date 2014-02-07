package main

import (
	"fmt"
	"koding/workers/neo4jfeeder/mongohelper"
	"log"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

func init() {
	log.SetPrefix("Externals: ")
}

// Stores the current adapter used to talk to the database.
var mongo DocumentDB

// Definition of a document db interface. We use an interface
// here, so it's easy to mock in tests.
type DocumentDB interface {
	GetUser(string) (strToInf, bool)
	GetTagByName(string, string) (strToInf, bool)
	GetUserByProviderId(string, string) (strToInf, bool)
}

// A Mongo implementation of the `DocumentDB` interface.
type Mongo struct{}

func (n *Mongo) GetUser(userId string) (strToInf, bool) {
	user, err := mongohelper.Fetch(userId, "jAccount")
	if user == nil || err != nil {
		log.Println(err)
		return nil, false
	}

	return user, true
}

func (n *Mongo) GetTagByName(title, name string) (strToInf, bool) {
	query := func() map[string]interface{} {
		var tag map[string]interface{}
		mongoDB.Run("jTags", func(c *mgo.Collection) error {
			return c.Find(
				bson.M{"title": bson.RegEx{
					Pattern: "^" + title, Options: "i"},
				}).Limit(1).One(&tag)
		})

		return tag
	}

	tagContent, err := mongohelper.FetchOneContentBy(query)
	if err != nil {
		return tagContent, false
	}

	return tagContent, true
}

func (n *Mongo) GetUserByProviderId(id, provider string) (strToInf, bool) {
	query := func() map[string]interface{} {
		var user map[string]interface{}

		mongoDB.Run("jUsers", func(c *mgo.Collection) error {
			field := fmt.Sprintf("foreignAuth.%v.foreignId", provider)
			return c.Find(bson.M{field: id}).Limit(1).One(&user)
		})

		return user
	}

	userContent, err := mongohelper.FetchOneContentBy(query)
	if err != nil {
		return userContent, false
	}

	return userContent, true
}
