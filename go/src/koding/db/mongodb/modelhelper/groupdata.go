package modelhelper

import (
	"koding/db/models"
	"strings"

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
	// Insert with internally created id.
	op := func(c *mgo.Collection) error {
		mpath := PreparePath(path, data)
		_, err := c.Upsert(
			bson.M{"slug": slug},
			bson.M{
				"$set": bson.M{
					"data": mpath,
				},
			},
		)
		return err
	}

	return Mongo.Run(GroupDataColl, op)
}

// PreparePath walks recursively according to given path and puts the data down
// in end of the path.
func PreparePath(path string, data interface{}) bson.M {
	paths := strings.Split(path, ".")
	res := bson.M{}
	for i := len(paths) - 1; i >= 0; i-- {
		lpath := paths[i]
		if i == len(paths)-1 {
			res = bson.M{lpath: data}
		} else {
			res = bson.M{lpath: res}
		}
	}

	return res
}
