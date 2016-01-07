package main

import (
	"koding/db/mongodb/modelhelper"
	"testing"
	"time"

	"gopkg.in/mgo.v2/bson"

	. "github.com/smartystreets/goconvey/convey"
)

func TestWarningsQuery(t *testing.T) {
	Convey("Given user who is inactive & not warned", t, func() {
		warning := VMDeletionWarning1

		user, err := createInactiveUser(21)
		So(err, ShouldBeNil)

		Convey("Then it should fetch the user", func() {
			newuser, err := modelhelper.GetUserByQuery(warning.Select[0])
			So(err, ShouldBeNil)

			So(newuser.ObjectId, ShouldEqual, user.ObjectId)
		})

		Reset(func() {
			deleteUserWithUsername(user)
		})
	})

	Convey("Given user who is inactive & warned", t, func() {
		warning := VMDeletionWarning2

		user, err := createInactiveUserWithWarning(25, warning.ID)
		So(err, ShouldBeNil)

		Convey("Then it should fetch the user", func() {
			newuser, err := modelhelper.GetUserByQuery(warning.Select[0])
			So(err, ShouldBeNil)

			So(newuser.ObjectId, ShouldEqual, user.ObjectId)
		})

		Reset(func() {
			deleteUserWithUsername(user)
		})
	})

	Convey("Given user who is inactive & warned twice", t, func() {
		warning := DeleteInactiveUserVM

		user, err := createInactiveUserWithWarning(30, warning.ID)
		So(err, ShouldBeNil)

		Convey("Then it should fetch the user", func() {
			newuser, err := modelhelper.GetUserByQuery(warning.Select[0])
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
		user, err := createInactiveUser(21)
		So(err, ShouldBeNil)

		resetFakeEmails()

		warning := VMDeletionWarning1
		warning.ExemptCheckers = []*ExemptChecker{}
		warning.Action = fakeEmailActionFn()

		warning.Run()

		Convey("Then they should get an email", func() {
			So(len(fakeEmails), ShouldEqual, 1)
			So(fakeEmails[0], ShouldEqual, warning.ID)
		})

		Reset(func() {
			deleteUserWithUsername(user)
		})
	})

	Convey("Given user who is inactive & been warned", t, func() {
		user, err := createInactiveUser(21)
		So(err, ShouldBeNil)

		resetFakeEmails()

		warning := VMDeletionWarning1
		warning.ExemptCheckers = []*ExemptChecker{}
		warning.Action = fakeEmailActionFn()
		warning.Run()

		So(len(fakeEmails), ShouldEqual, 1)
		So(fakeEmails[0], ShouldEqual, warning.ID)

		Convey("Then they should get an email", func() {
			user, err := modelhelper.GetUser(user.Name)
			So(err, ShouldBeNil)
			So(user.Inactive.Warning, ShouldEqual, warning.ID)

			Convey("Then they should get another email", func() {
				selector := bson.M{"username": user.Name}
				update := bson.M{
					"lastLoginDate": timeNow().Add(-time.Hour * 24 * time.Duration(25)),
				}

				err := modelhelper.UpdateUser(selector, update)
				So(err, ShouldBeNil)

				updateUserModifiedAt(user, yesterday())

				resetFakeEmails()

				warning := VMDeletionWarning2
				warning.ExemptCheckers = []*ExemptChecker{}
				warning.Action = fakeEmailActionFn()

				warning.Run()

				So(len(fakeEmails), ShouldEqual, 1)
				So(fakeEmails[0], ShouldEqual, warning.ID)

				user, err := modelhelper.GetUser(user.Name)
				So(err, ShouldBeNil)
				So(user.Inactive.Warning, ShouldEqual, warning.ID)
			})
		})

		Reset(func() {
			deleteUserWithUsername(user)
		})
	})
}
