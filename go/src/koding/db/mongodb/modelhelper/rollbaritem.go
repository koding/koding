package modelhelper

import (
	"koding/db/models"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

var RollbarIemCollection = "rollbarItems"

func UpsertByItemId(r *models.RollbarItem) error {
	var query = func(c *mgo.Collection) error {
		var _, err = c.Upsert(bson.M{"itemId": r.ItemId}, r)
		return err
	}

	return Mongo.Run(RollbarIemCollection, query)
}

func FindByCodeVersion(r *models.RollbarItem) ([]*models.RollbarItem, error) {
	var foundItems []*models.RollbarItem
	var findQuery = func(c *mgo.Collection) error {
		return c.Find(bson.M{"codeVersion": r.CodeVersion}).All(&foundItems)
	}

	var err = Mongo.Run(RollbarIemCollection, findQuery)

	return foundItems, err
}
