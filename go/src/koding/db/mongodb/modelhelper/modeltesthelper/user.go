package modeltesthelper

import (
	"koding/db/models"
	"koding/db/mongodb/modelhelper"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

func CreateUser(username string) (*models.User, error) {
	user := &models.User{
		ObjectId: bson.NewObjectId(), Name: username,
	}

	query := func(c *mgo.Collection) error {
		return c.Insert(user)
	}

	err := modelhelper.Mongo.Run(modelhelper.UserColl, query)
	if err != nil {
		return nil, err
	}

	return user, nil
}

func DeleteUser(userId bson.ObjectId) error {
	query := func(c *mgo.Collection) error {
		return c.Remove(bson.M{"_id": userId})
	}

	return modelhelper.Mongo.Run(modelhelper.UserColl, query)
}

func DeleteUsersByUsername(username string) error {
	query := func(c *mgo.Collection) error {
		_, err := c.RemoveAll(bson.M{"username": username})
		return err
	}

	return modelhelper.Mongo.Run(modelhelper.UserColl, query)
}

func DeleteUsersAndMachines(username string) error {
	query := func(c *mgo.Collection) error {
		_, err := c.RemoveAll(bson.M{"username": username})
		return err
	}

	return modelhelper.Mongo.Run(modelhelper.UserColl, query)
}
