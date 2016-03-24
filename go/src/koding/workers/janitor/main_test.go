package main

import (
	"github.com/jinzhu/now"

	"gopkg.in/mgo.v2/bson"

	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/db/mongodb/modelhelper/modeltesthelper"
	"time"
)

func init() {
	j.initializeRunner()
}

//----------------------------------------------------------
// helpers
//----------------------------------------------------------

var fakeEmails = []string{}

func resetFakeEmails() {
	fakeEmails = []string{}
}

func createInactiveUserWithWarning(daysInactive int, w string) (*models.User, error) {
	username := bson.NewObjectId().Hex()
	user := &models.User{
		ObjectId:      bson.NewObjectId(),
		Name:          username,
		Email:         username + "@koding.com",
		LastLoginDate: timeNow().Add(-time.Hour * 24 * time.Duration(daysInactive)),
		Inactive: &models.UserInactive{
			Warning:    w,
			ModifiedAt: timeNow(),
			Warnings: map[string]time.Time{
				w: timeNow(),
			},
		},
	}

	_, err := modeltesthelper.CreateUserWithQuery(user)
	if err != nil {
		return nil, err
	}

	return user, nil
}

func createUserWithVM() (*models.User, error) {
	username := bson.NewObjectId().Hex()
	user, _, err := modeltesthelper.CreateUser(username)
	if err != nil {
		return nil, err
	}

	machine := &models.Machine{ObjectId: bson.NewObjectId(), Provider: "koding"}
	return user, modelhelper.CreateMachineForUser(machine, user)
}

func createUserWithManagedVM() (*models.User, error) {
	username := bson.NewObjectId().Hex()
	user, _, err := modeltesthelper.CreateUser(username)
	if err != nil {
		return nil, err
	}

	machine := &models.Machine{ObjectId: bson.NewObjectId(), Provider: "managed"}
	return user, modelhelper.CreateMachineForUser(machine, user)
}

func createInactiveUser(daysInactive int) (*models.User, error) {
	username := bson.NewObjectId().Hex()
	user := &models.User{
		Name:          username,
		ObjectId:      bson.NewObjectId(),
		Email:         username + "@koding.com",
		LastLoginDate: timeNow().Add(-time.Hour * 24 * time.Duration(daysInactive)),
	}

	_, err := modeltesthelper.CreateUserWithQuery(user)
	if err != nil {
		return nil, err
	}

	return user, nil
}

func deleteUserWithUsername(user *models.User) {
	modelhelper.RemoveAllUsers(user.Name)
	modelhelper.RemoveAllAccountByUsername(user.Name)
	modelhelper.RemoveAllMachinesForUser(user.ObjectId)
}

func yesterday() time.Time {
	return now.BeginningOfDay().UTC()
}

func updateUserModifiedAt(user *models.User, m time.Time) error {
	selector := bson.M{"username": user.Name}
	update := bson.M{"inactive.modifiedAt": m}

	return modelhelper.UpdateUser(selector, update)
}

func fakeEmailActionFn() func(user *models.User, w string) error {
	return func(user *models.User, w string) error {
		fakeEmails = append(fakeEmails, w)
		return nil
	}
}
