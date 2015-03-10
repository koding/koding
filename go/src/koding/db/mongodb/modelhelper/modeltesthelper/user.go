package modeltesthelper

import (
	"koding/db/models"
	"koding/db/mongodb/modelhelper"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

func CreateUser(username string) (*models.User, *models.Account, error) {
	user := &models.User{
		ObjectId: bson.NewObjectId(), Name: username,
	}

	userQuery := func(c *mgo.Collection) error {
		return c.Insert(user)
	}

	err := modelhelper.Mongo.Run(modelhelper.UserColl, userQuery)
	if err != nil {
		return nil, nil, err
	}

	account := &models.Account{
		Id:      bson.NewObjectId(),
		Profile: models.AccountProfile{Nickname: username},
	}

	accQuery := func(c *mgo.Collection) error {
		return c.Insert(account)
	}

	err = modelhelper.Mongo.Run(modelhelper.AccountsColl, accQuery)
	if err != nil {
		return nil, nil, err
	}

	return user, account, nil
}

func DeleteUser(userId bson.ObjectId) error {
	user, err := modelhelper.GetUserById(userId.Hex())
	if err != nil {
		return err
	}

	userQuery := func(c *mgo.Collection) error {
		return c.Remove(bson.M{"_id": userId})
	}

	err = modelhelper.Mongo.Run(modelhelper.UserColl, userQuery)
	if err != nil {
		return err
	}

	accQuery := func(c *mgo.Collection) error {
		return c.Remove(bson.M{"profile.nickname": user.Name})
	}

	return modelhelper.Mongo.Run(modelhelper.AccountsColl, accQuery)
}

func DeleteUsersByUsername(username string) error {
	accQuery := func(c *mgo.Collection) error {
		_, err := c.RemoveAll(bson.M{"username": username})
		return err
	}

	err := modelhelper.Mongo.Run(modelhelper.UserColl, accQuery)
	if err != nil {
		return err
	}

	userQuery := func(c *mgo.Collection) error {
		_, err := c.RemoveAll(bson.M{"profile.nickname": username})
		return err
	}

	return modelhelper.Mongo.Run(modelhelper.UserColl, userQuery)
}

func DeleteUsersAndMachines(username string) error {
	user, err := modelhelper.GetUser(username)
	if err != nil {
		return err
	}

	err = DeleteUsersByUsername(username)
	if err != nil {
		return err
	}

	deleteQuery := func(c *mgo.Collection) error {
		_, err := c.RemoveAll(bson.M{"users.id": user.ObjectId})
		return err
	}

	return modelhelper.Mongo.Run(modelhelper.MachineColl, deleteQuery)
}
