package modelhelper

import (
	"errors"
	"koding/db/models"

	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

// GroupDataColl holds the collection name for JGroupData model.
const GroupDataColl = "jGroupDatas"

// GetGroupData fetches the group data from db.
func GetGroupData(slug string) (*models.GroupData, error) {
	gd := new(models.GroupData)

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"slug": slug}).One(&gd)
	}

	err := Mongo.Run(GroupDataColl, query)
	if err != nil {
		return nil, err
	}

	return gd, nil
}

// UpsertGroupData creates or updates GroupData.
func UpsertGroupData(slug, path string, data interface{}) error {
	if path == "" {
		return errors.New("path is not set")
	}

	// Insert with internally created id.
	op := func(c *mgo.Collection) error {
		_, err := c.Upsert(
			bson.M{"slug": slug},
			bson.M{
				"$set": bson.M{
					"data." + path: data,
				},
			},
		)
		return err
	}

	return Mongo.Run(GroupDataColl, op)
}
