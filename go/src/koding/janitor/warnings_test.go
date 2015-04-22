package main

import (
	"koding/db/mongodb/modelhelper"
	"testing"
	"time"

	"labix.org/v2/mgo/bson"

	. "github.com/smartystreets/goconvey/convey"
)

func TestWarningsQuery(t *testing.T) {
	Convey("Given user who is inactive & not warned", t, func() {
		warning := Warnings[0]

		user, err := createInactiveUser(warning.Interval + 1)
		So(err, ShouldBeNil)

		Convey("Then it should fetch the user", func() {
			newuser, err := findUserByQuery(warning.Select)
			So(err, ShouldBeNil)

			So(newuser.ObjectId, ShouldEqual, user.ObjectId)
		})

		Reset(func() {
			deleteUserWithUsername(user)
		})
	})

	Convey("Given user who is inactive & warned", t, func() {
		warning := Warnings[1]

		user, err := createInactiveUserWithWarning(warning.Interval+1,
			warning.Level-1)
		So(err, ShouldBeNil)

		Convey("Then it should fetch the user", func() {
			newuser, err := findUserByQuery(warning.Select)
			So(err, ShouldBeNil)

			So(newuser.ObjectId, ShouldEqual, user.ObjectId)
		})

		Reset(func() {
			deleteUserWithUsername(user)
		})
	})

	Convey("Given user who is inactive & warned thrice", t, func() {
		warning := Warnings[2]

		user, err := createInactiveUserWithWarning(warning.Interval+1,
			warning.Level-1)
		So(err, ShouldBeNil)

		Convey("Then it should fetch the user", func() {
			newuser, err := findUserByQuery(warning.Select)
			So(err, ShouldBeNil)

			So(newuser.ObjectId, ShouldEqual, user.ObjectId)
		})

		Reset(func() {
			deleteUserWithUsername(user)
		})
	})
}

var fakeEmails = []int{}

func TestWarningsFull(t *testing.T) {
	Convey("Given user who is inactive & not warned", t, func() {
		user, err := createInactiveUser(46)
		So(err, ShouldBeNil)

		resetFakeEmails()

		warning := Warnings[0]
		warning.Exempt = []Exempt{}
		warning.Action = fakeEmailActionFn()
		warning.Run()

		Convey("Then they should get an email", func() {
			So(len(fakeEmails), ShouldEqual, 1)
			So(fakeEmails[0], ShouldEqual, 1)
		})

		Reset(func() {
			deleteUserWithUsername(user)
		})
	})

	Convey("Given user who is inactive & been warned", t, func() {
		user, err := createInactiveUser(46)
		So(err, ShouldBeNil)

		resetFakeEmails()

		warning := Warnings[0]
		warning.Exempt = []Exempt{}
		warning.Action = fakeEmailActionFn()
		warning.Run()

		So(len(fakeEmails), ShouldEqual, 1)
		So(fakeEmails[0], ShouldEqual, 1)

		Convey("Then they should get an email", func() {
			user, err := modelhelper.GetUser(user.Name)
			So(err, ShouldBeNil)
			So(user.Inactive.Warning, ShouldEqual, 1)

			Convey("Then they should get another email", func() {
				selector := bson.M{"username": user.Name}
				update := bson.M{
					"lastLoginDate": timeNow().Add(-time.Hour * 24 * time.Duration(53)),
				}

				err := modelhelper.UpdateUser(selector, update)
				So(err, ShouldBeNil)

				updateUserModifiedAt(user, yesterday())

				resetFakeEmails()

				warning := Warnings[1]
				warning.Exempt = []Exempt{}
				warning.Action = fakeEmailActionFn()
				warning.Run()

				So(len(fakeEmails), ShouldEqual, 1)
				So(fakeEmails[0], ShouldEqual, 2)

				user, err := modelhelper.GetUser(user.Name)
				So(err, ShouldBeNil)
				So(user.Inactive.Warning, ShouldEqual, 2)
			})
		})

		Reset(func() {
			deleteUserWithUsername(user)
		})
	})
}
