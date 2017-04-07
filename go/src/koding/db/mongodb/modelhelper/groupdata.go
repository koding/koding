package modelhelper

import (
	"errors"
	"koding/db/models"

	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

// GroupDataColl holds the collection name for JGroupData model.
const GroupDataColl = "jGroupDatas"

var errPathNotSet = errors.New("path is not set")

// GetGroupData fetches the group data from db.
func GetGroupData(slug string, gd interface{}) error {
	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"slug": slug}).One(gd)
	}

	return Mongo.Run(GroupDataColl, query)
}

// GetGroupDataPath fetches the group data from db but only the given path.
func GetGroupDataPath(slug, path string, gd interface{}) error {
	if path == "" {
		return errPathNotSet
	}

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"slug": slug}).Select(bson.M{"payload." + path: 1}).One(gd)
	}

	return Mongo.Run(GroupDataColl, query)
}

// UpsertGroupData creates or updates GroupData.
func UpsertGroupData(slug, path string, data interface{}) error {
	if path == "" {
		return errPathNotSet
	}

	// Insert with internally created id.
	op := func(c *mgo.Collection) error {
		_, err := c.Upsert(
			bson.M{"slug": slug},
			bson.M{
				"$set": bson.M{
					"payload." + path: data,
				},
			},
		)
		return err
	}

	return Mongo.Run(GroupDataColl, op)
}

// FetchCountlyInfo gets the countly data for a given group
func FetchCountlyInfo(slug string) (*models.Countly, error) {
	type countly struct {
		Payload struct {
			Countly *models.Countly
		}
	}
	res := &countly{}
	if err := GetGroupDataPath(slug, "countly", res); err != nil {
		return nil, err
	}
	return res.Payload.Countly, nil
}
