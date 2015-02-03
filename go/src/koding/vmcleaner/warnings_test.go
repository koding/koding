package main

import (
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"testing"
	"time"

	"labix.org/v2/mgo/bson"

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

func TestLockAndReleaseUser(t *testing.T) {
	Convey("Given user who is inactive & not warned", t, func() {
		user, err := createInactiveUser(46)
		So(err, ShouldBeNil)

		Convey("Then it should find and lock user", func() {
			newuser, err := FirstEmail.FindAndLockUser()
			So(err, ShouldBeNil)

			So(newuser.ObjectId, ShouldEqual, user.ObjectId)
			So(newuser.Inactive.Assigned, ShouldBeTrue)

			Convey("When it releases user", func() {
				err := FirstEmail.UpdateAndReleaseUser(user.ObjectId)
				So(err, ShouldBeNil)

				Convey("Then it should update user", func() {
					updatedUser, err := findUser(user.Name)
					So(err, ShouldBeNil)

					So(updatedUser.Inactive.Warning, ShouldEqual, FirstEmail.Level)
					So(updatedUser.Inactive.ModifiedAt.IsZero(), ShouldBeFalse)

					So(updatedUser.Inactive.WarningTime, ShouldNotBeNil)
					So(updatedUser.Inactive.WarningTime.One.IsZero(), ShouldBeFalse)
				})

				Convey("Then it shouldn't get same user again", func() {
					_, err := FirstEmail.FindAndLockUser()
					So(err, ShouldNotBeNil)
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
				Exempt: []Exempt{func(user *models.User) bool {
					return true
				}},
			}

			So(warning.IsUserExempt(user), ShouldBeTrue)
		})

		Convey("Then it should not be exempt", func() {
			warning := &Warning{
				Exempt: []Exempt{func(user *models.User) bool {
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

				Exempt: []Exempt{func(user *models.User) bool {
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

				Exempt: []Exempt{func(user *models.User) bool {
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
