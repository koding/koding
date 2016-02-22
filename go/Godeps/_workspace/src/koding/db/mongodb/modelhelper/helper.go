package modelhelper

import (
	"strings"

	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"

	"github.com/chuckpreslar/inflect"
)

// GetCollectionName returns model name as collection name
// in mongo collection names are persisted as "<lowercase_first_letter>...<add (s)>
// e.g if name is Koding, in database it is "kodings"
func GetCollectionName(name string) string {
	// pluralize the name
	name = inflect.Pluralize(name)

	//split name into string array
	splittedName := strings.Split(name, "")

	//uppercase first character and assign back
	splittedName[0] = strings.ToLower(splittedName[0])

	//merge string array
	name = strings.Join(splittedName, "")
	return name

}

// Delete document deletes given id from given collection
func RemoveDocument(collectionName string, id bson.ObjectId) error {
	return Mongo.Run(collectionName, func(coll *mgo.Collection) error {
		return coll.RemoveId(id)
	})
}

// RemoveAllDocuments removes documents from database if they satisfies the query
func RemoveAllDocuments(collectionName string, selector Selector) error {
	query := func(c *mgo.Collection) error {
		_, err := c.RemoveAll(selector)
		return err
	}

	return Mongo.Run(collectionName, query)
}
