package main

import (
	"github.com/koding/kodingemail"
	"labix.org/v2/mgo/bson"

	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"testing"
	"time"

	. "github.com/smartystreets/goconvey/convey"
)

func init() {
	initializeMongo("localhost:27017/koding")
	email = initializeEmail("", "")
}

func TestWarningsFull(t *testing.T) {
	Convey("Given user who is inactive & not warned", t, func() {
		user, err := createInactiveUser(46)
		So(err, ShouldBeNil)

		senderTestClient := &kodingemail.SenderTestClient{}
		email.SetClient(senderTestClient)

		warning := FirstEmail
		warning.Run()

		Convey("Then they should get an email", func() {
			So(senderTestClient.Mail, ShouldNotBeNil)
			So(len(senderTestClient.Mail.To), ShouldEqual, 1)
			So(senderTestClient.Mail.To[0], ShouldEqual, user.Email)
		})

		Reset(func() {
			deleteUserWithUsername(user)
		})
	})

	Convey("Given user who is inactive & been warned", t, func() {
		user, err := createInactiveUser(46)
		So(err, ShouldBeNil)

		senderTestClient := resetEmailClient()

		warning := FirstEmail
		warning.Run()

		Convey("Then they should get an email", func() {
			So(senderTestClient.Mail, ShouldNotBeNil)
			So(len(senderTestClient.Mail.To), ShouldEqual, 1)
			So(senderTestClient.Mail.To[0], ShouldEqual, user.Email)

			user, err := modelhelper.GetUser(user.Name)
			So(err, ShouldBeNil)
			So(user.Inactive.Warning, ShouldEqual, 1)

			Convey("Then they should get another email", func() {
				selector := bson.M{"username": user.Name}
				update := bson.M{
					"lastLoginDate": now().Add(-time.Hour * 24 * time.Duration(53)),
				}

				err := modelhelper.UpdateUser(selector, update)
				So(err, ShouldBeNil)

				// senderTestClient := resetEmailClient()

				warning := SecondEmail
				warning.Run()

				So(senderTestClient.Mail, ShouldNotBeNil)
				So(len(senderTestClient.Mail.To), ShouldEqual, 1)
				So(senderTestClient.Mail.To[0], ShouldEqual, user.Email)

				user, err := modelhelper.GetUser(user.Name)
				So(err, ShouldBeNil)
				So(user.Inactive.Warning, ShouldEqual, 2)

				Convey("Then their vm should be deleted", func() {
					selector := bson.M{"username": user.Name}
					update := bson.M{
						"lastLoginDate": now().Add(-time.Hour * 24 * time.Duration(65)),
					}

					err := modelhelper.UpdateUser(selector, update)
					So(err, ShouldBeNil)

					warning := ThirdDeleteVM
					warning.Run()

					user, err := modelhelper.GetUser(user.Name)
					So(err, ShouldBeNil)
					So(user.Inactive.Warning, ShouldEqual, 3)
				})
			})
		})

		Reset(func() {
			deleteUserWithUsername(user)
		})
	})
}

//----------------------------------------------------------
// helpers
//----------------------------------------------------------

func createUser() (*models.User, error) {
	username := "vminactive"
	user := &models.User{
		Name: username, ObjectId: bson.NewObjectId(),
	}

	return user, modelhelper.CreateUser(user)
}

func createUserWithVM() (*models.User, error) {
	username := "vminactiveWithvms"
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
		LastLoginDate: now().Add(-time.Hour * 24 * time.Duration(daysInactive)),
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

func resetEmailClient() *kodingemail.SenderTestClient {
	senderTestClient := &kodingemail.SenderTestClient{}
	email.SetClient(senderTestClient)

	return senderTestClient
}
