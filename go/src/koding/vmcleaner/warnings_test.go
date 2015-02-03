package main

import (
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"testing"
	"time"

	"labix.org/v2/mgo/bson"

	"github.com/koding/kodingemail"
	. "github.com/smartystreets/goconvey/convey"
)

func TestWarningsQuery(t *testing.T) {
	Convey("Given user who is inactive & not warned", t, func() {
		user, err := createInactiveUser(46)
		So(err, ShouldBeNil)

		Convey("Then it should fetch the user", func() {
			newuser, err := FirstEmail.FindUser()
			So(err, ShouldBeNil)

			So(newuser.ObjectId, ShouldEqual, user.ObjectId)
		})

		Reset(func() {
			deleteUserWithUsername(user)
		})
	})

	Convey("Given user who is inactive & warned", t, func() {
		user := &models.User{
			Name: "inactiveuser", ObjectId: bson.NewObjectId(),
			LastLoginDate: time.Now().Add(-time.Hour * 24 * 53),
			Inactive:      models.UserInactive{Warning: 1},
		}

		err := modelhelper.CreateUser(user)
		So(err, ShouldBeNil)

		Convey("Then it should fetch the user", func() {
			newuser, err := SecondEmail.FindUser()
			So(err, ShouldBeNil)

			So(newuser.ObjectId, ShouldEqual, user.ObjectId)
		})

		Reset(func() {
			modelhelper.RemoveUser(user.Name)
		})
	})

	Convey("Given user who is inactive & warned twice", t, func() {
		user := &models.User{
			Name: "inactiveuser", ObjectId: bson.NewObjectId(),
			LastLoginDate: now().Add(-time.Hour * 24 * 61),
			Inactive:      models.UserInactive{Warning: 2},
		}

		err := modelhelper.CreateUser(user)
		So(err, ShouldBeNil)

		Convey("Then it should fetch the user", func() {
			newuser, err := ThirdDeleteVM.FindUser()
			So(err, ShouldBeNil)

			So(newuser.ObjectId, ShouldEqual, user.ObjectId)
		})

		Reset(func() {
			deleteUserWithUsername(user)
		})
	})
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
