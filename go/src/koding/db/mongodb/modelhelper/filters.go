package modelhelper

import (
	"koding/db/models"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

func GetFilterByID(id bson.ObjectId) (models.Filter, error) {
	filter := models.Filter{}
	query := func(c *mgo.Collection) error {
		return c.FindId(id).One(&filter)
	}

	err := Mongo.Run("jProxyFilters", query)
	if err != nil {
		return models.Filter{}, err
	}
	return filter, nil
}
