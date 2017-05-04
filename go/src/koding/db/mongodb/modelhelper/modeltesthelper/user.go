package modeltesthelper

import (
	"koding/db/models"
	"koding/db/mongodb/modelhelper"

	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

// CreateUserWithNick creates a test user.
func CreateUser(username string) (*models.User, *models.Account, error) {
	accID := bson.NewObjectId()
	accHex := accID.Hex()
	user := &models.User{
		ObjectId:       accID,
		Password:       accHex,
		Salt:           accHex,
		Name:           username,
		Email:          accHex + "@koding.com",
		SanitizedEmail: accHex + "@koding.com",
		Status:         "confirmed",
		EmailFrequency: &models.EmailFrequency{},
	}

	account, err := CreateUserWithQuery(user)
	return user, account, err
}

func CreateUserWithQuery(user *models.User) (*models.Account, error) {
	userQuery := func(c *mgo.Collection) error {
		return c.Insert(user)
	}

	err := modelhelper.Mongo.Run(modelhelper.UserColl, userQuery)
	if err != nil {
		return nil, err
	}

	account := &models.Account{
		Id:      bson.NewObjectId(),
		Profile: models.AccountProfile{Nickname: user.Name},
	}

	accQuery := func(c *mgo.Collection) error {
		return c.Insert(account)
	}

	err = modelhelper.Mongo.Run(modelhelper.AccountsColl, accQuery)
	if err != nil {
		return nil, err
	}

	return account, nil
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

	return modelhelper.Mongo.Run(modelhelper.MachinesColl, deleteQuery)
}
