package main

import (
	"fmt"

	"github.com/jinzhu/now"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"

	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"time"
)

func init() {
	modelhelper.Initialize("localhost:27017/koding_test")
	Log.SetLevel(0)
}

//----------------------------------------------------------
// helpers
//----------------------------------------------------------

func createUser() (*models.User, error) {
	username := "regularuser"
	user := &models.User{
		Name: username, ObjectId: bson.NewObjectId(),
	}

	return user, modelhelper.CreateUser(user)
}

func createUserWithWarning(w int, m time.Time) (*models.User, error) {
	username := "userwithwarning"
	user := &models.User{
		Name: username, ObjectId: bson.NewObjectId(),
		Inactive: models.UserInactive{Warning: w, ModifiedAt: m},
	}

	return user, modelhelper.CreateUser(user)
}

func createInactiveUserWithWarning(daysInactive, w int) (*models.User, error) {
	username := "inactiveuserwithwarning"
	user := &models.User{
		Name: username, ObjectId: bson.NewObjectId(),
		Email:         "inactiveuser@koding.com",
		LastLoginDate: timeNow().Add(-time.Hour * 24 * time.Duration(daysInactive)),
		Inactive: models.UserInactive{
			Warning: w, ModifiedAt: timeNow(),
			Warnings: map[string]time.Time{fmt.Sprintf("%d", w): timeNow()},
		},
	}

	return user, modelhelper.CreateUser(user)
}

func createUserWithVM() (*models.User, error) {
	username := "userwithvms"
	user := &models.User{
		Name: username, ObjectId: bson.NewObjectId(),
	}

	machine := &models.Machine{ObjectId: bson.NewObjectId()}

	err := modelhelper.CreateMachineForUser(machine, user)
	if err != nil {
		return nil, err
	}

	return user, modelhelper.CreateUser(user)
}

func createInactiveUser(daysInactive int) (*models.User, error) {
	user := &models.User{
		Name: "inactiveuser", ObjectId: bson.NewObjectId(),
		Email:         "inactiveuser@koding.com",
		LastLoginDate: timeNow().Add(-time.Hour * 24 * time.Duration(daysInactive)),
	}

	return user, modelhelper.CreateUser(user)
}

func deleteUserWithUsername(user *models.User) {
	modelhelper.RemoveAllUsers(user.Name)
	modelhelper.RemoveAllAccountByUsername(user.Name)
	modelhelper.RemoveAllMachinesForUser(user.ObjectId)
}

func findUser(username string) (*models.User, error) {
	return modelhelper.GetUser(username)
}

func findUserByQuery(selector bson.M) (*models.User, error) {
	var user *models.User

	query := func(c *mgo.Collection) error {
		return c.Find(selector).One(&user)
	}

	return user, modelhelper.Mongo.Run(modelhelper.UserColl, query)
}

func yesterday() time.Time {
	return now.BeginningOfDay().UTC()
}

func updateUserModifiedAt(user *models.User, m time.Time) error {
	selector := bson.M{"username": user.Name}
	update := bson.M{"inactive.modifiedAt": m}

	return modelhelper.UpdateUser(selector, update)
}
