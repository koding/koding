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
			modelhelper.RemoveUser(user.Name)
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
			modelhelper.RemoveUser(user.Name)
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

			Convey("Then it should release user", func() {
				err := FirstEmail.UpdateAndReleaseUser(user.ObjectId)
				So(err, ShouldBeNil)

				Convey("Then it shouldn't get same user again", func() {
					_, err := FirstEmail.FindAndLockUser()
					So(err, ShouldNotBeNil)
				})
			})
		})

		Reset(func() {
			modelhelper.RemoveUser(user.Name)
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
			modelhelper.RemoveUser(user.Name)
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
		})
	})
}

func createUser() (*models.User, error) {
	username := "paiduser"
	user := &models.User{
		Name: username, ObjectId: bson.NewObjectId(), Status: "blocked",
	}

	return user, modelhelper.CreateUser(user)
}

func createInactiveUser(daysInactive int) (*models.User, error) {
	user := &models.User{
		Name: "inactiveuser", ObjectId: bson.NewObjectId(),
		LastLoginDate: now().Add(-time.Hour * 24 * time.Duration(daysInactive)),
	}

	return user, modelhelper.CreateUser(user)
}
