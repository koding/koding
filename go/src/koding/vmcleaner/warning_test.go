package main

import (
	"fmt"
	"koding/db/models"
	"testing"

	"labix.org/v2/mgo/bson"

	. "github.com/smartystreets/goconvey/convey"
)

func TestLockAndReleaseUser(t *testing.T) {
	Convey("Given user", t, func() {
		level := 9001

		user, err := createUserWithWarning(level - 1)
		So(err, ShouldBeNil)

		warning := &Warning{
			Select: bson.M{"username": user.Name, "inactive.warning": level - 1},
			Level:  level,
		}

		Convey("Then it should find and lock user", func() {
			newuser, err := warning.FindAndLockUser()
			So(err, ShouldBeNil)

			So(newuser.ObjectId, ShouldEqual, user.ObjectId)
			So(newuser.Inactive.Assigned, ShouldBeTrue)

			Convey("When it releases user", func() {
				err := warning.UpdateAndReleaseUser(user.ObjectId)
				So(err, ShouldBeNil)

				Convey("Then it should update user for next level", func() {
					updatedUser, err := findUser(user.Name)
					So(err, ShouldBeNil)

					So(updatedUser.Inactive.Warning, ShouldEqual, level)
					So(updatedUser.Inactive.ModifiedAt.IsZero(), ShouldBeFalse)

					warnings := updatedUser.Inactive.Warnings

					So(warnings, ShouldNotBeNil)
					So(warnings[fmt.Sprintf("%v", level)], ShouldNotBeNil)
					So(warnings[fmt.Sprintf("%v", level)].IsZero(), ShouldBeFalse)

					Convey("Then it shouldn't get same user again", func() {
						_, err := warning.FindAndLockUser()
						So(err, ShouldNotBeNil)
					})
				})
			})
		})

		Reset(func() {
			deleteUserWithUsername(user)
		})
	})
}

func TestIsUserExempt(t *testing.T) {
	Convey("Given exempt conditions", t, func() {
		user, err := createUser()
		So(err, ShouldBeNil)

		Convey("Then it should be exempt", func() {
			warning := &Warning{
				Exempt: []Exempt{func(_ *models.User, _ *Warning) bool {
					return true
				}},
			}

			So(warning.IsUserExempt(user), ShouldBeTrue)
		})

		Convey("Then it should not be exempt", func() {
			warning := &Warning{
				Exempt: []Exempt{func(_ *models.User, _ *Warning) bool {
					return false
				}},
			}

			So(warning.IsUserExempt(user), ShouldBeFalse)
		})

		Reset(func() {
			deleteUserWithUsername(user)
		})
	})
}

func TestAct(t *testing.T) {
	Convey("Given action", t, func() {
		Convey("Then it should call it if not exempt", func() {
			user, err := createUser()
			So(err, ShouldBeNil)

			var called = false

			warning := &Warning{
				Action: func(user *models.User, level int) error {
					called = true
					return nil
				},

				Exempt: []Exempt{func(user *models.User, _ *Warning) bool {
					return false
				}},
			}

			err = warning.Act(user)
			So(err, ShouldBeNil)
			So(called, ShouldBeTrue)

			Reset(func() {
				deleteUserWithUsername(user)
			})
		})

		Convey("Then it shouldn't call it if exempt", func() {
			user, err := createUser()
			So(err, ShouldBeNil)

			var called = false

			warning := &Warning{
				Action: func(user *models.User, level int) error {
					called = true
					return nil
				},

				Exempt: []Exempt{func(_ *models.User, _ *Warning) bool {
					return true
				}},
			}

			err = warning.Act(user)
			So(err, ShouldBeNil)
			So(called, ShouldBeFalse)

			Reset(func() {
				deleteUserWithUsername(user)
			})
		})
	})
}
