package modeltesthelper

import (
	"koding/db/models"
	"koding/db/mongodb/modelhelper"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

func CreateUser(user *models.User) error {
	query := func(c *mgo.Collection) error {
		return c.Insert(user)
	}

	return modelhelper.Mongo.Run(modelhelper.UserColl, query)
}

func DeleteUser(userId bson.ObjectId) error {
	query := func(c *mgo.Collection) error {
		return c.Remove(bson.M{"_id": userId})
	}

	return modelhelper.Mongo.Run(modelhelper.UserColl, query)
}
