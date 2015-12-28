package main

import (
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/db/mongodb/modelhelper/modeltesthelper"
	"testing"
	"time"

	"gopkg.in/mgo.v2/bson"

	. "github.com/smartystreets/goconvey/convey"
)

func TestReleaseUser(t *testing.T) {
	Convey("Given user", t, func() {
		username := "releaseuser"
		user, _, err := modeltesthelper.CreateUser(username)

		warning := &Warning{
			ID:     "warning",
			Select: []bson.M{bson.M{"username": user.Name}},
		}

		_, err = warning.FindAndLockUser()
		So(err, ShouldBeNil)

		Convey("When it releases user", func() {
			err = warning.ReleaseUser(user)
			So(err, ShouldBeNil)

			updatedUser, err := modelhelper.GetUser(user.Name)
			So(err, ShouldBeNil)

			Convey("Then it updates warning", func() {
				veryRecently := timeNow().Add(-1 * time.Second)
				So(updatedUser.Inactive.ModifiedAt.UTC(), ShouldHappenAfter,
					veryRecently)
			})
		})

		Reset(func() {
			deleteUserWithUsername(user)
		})
	})
}

func TestLockAndReleaseUser(t *testing.T) {
	Convey("Given user", t, func() {
		username := "releaseuser"
		user, _, err := modeltesthelper.CreateUser(username)
		So(err, ShouldBeNil)

		warning := &Warning{
			ID:     "warning",
			Select: []bson.M{bson.M{"username": user.Name}},
		}

		Convey("Then it shouldn't user if it was processed today", func() {
			err := updateUserModifiedAt(user, timeNow().Add(time.Hour*24))
			So(err, ShouldBeNil)

			_, err = warning.FindAndLockUser()
			So(err, ShouldNotBeNil)
		})

		Convey("Then it should find and lock user", func() {
			err := updateUserModifiedAt(user, timeNow().Add(-time.Hour*24))
			So(err, ShouldBeNil)

			newuser, err := warning.FindAndLockUser()
			So(err, ShouldBeNil)

			So(newuser.ObjectId, ShouldEqual, user.ObjectId)
			So(newuser.Inactive.Assigned, ShouldBeTrue)

			Convey("When it releases user", func() {
				err := warning.UpdateAndReleaseUser(user.ObjectId)
				So(err, ShouldBeNil)

				Convey("Then it should update user for next level", func() {
					updatedUser, err := modelhelper.GetUser(user.Name)
					So(err, ShouldBeNil)

					So(updatedUser.Inactive.Warning, ShouldEqual, warning.ID)
					So(updatedUser.Inactive.ModifiedAt.IsZero(), ShouldBeFalse)

					warnings := updatedUser.Inactive.Warnings

					So(warnings, ShouldNotBeNil)
					So(warnings[warning.ID], ShouldNotBeNil)
					So(warnings[warning.ID].IsZero(), ShouldBeFalse)

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
		username := "exempt"
		user, _, err := modeltesthelper.CreateUser(username)
		So(err, ShouldBeNil)

		Convey("Then it should be exempt", func() {
			warning := &Warning{
				ExemptCheckers: []*ExemptChecker{
					{
						Name: "",
						IsExempt: func(_ *models.User, _ *Warning) (bool, error) {
							return true, nil
						},
					},
				},
			}

			isExempt, err := warning.IsUserExempt(user)

			So(err, ShouldBeNil)
			So(isExempt, ShouldBeTrue)
		})

		Convey("Then it should not be exempt", func() {
			warning := &Warning{
				ExemptCheckers: []*ExemptChecker{
					{
						Name: "",
						IsExempt: func(_ *models.User, _ *Warning) (bool, error) {
							return false, nil
						},
					},
				},
			}

			isExempt, err := warning.IsUserExempt(user)

			So(err, ShouldBeNil)
			So(isExempt, ShouldBeFalse)
		})

		Convey("Then it should be exempt even if one condition is exempt", func() {
			warning := &Warning{
				ExemptCheckers: []*ExemptChecker{
					{
						Name: "",
						IsExempt: func(_ *models.User, _ *Warning) (bool, error) {
							return false, nil
						},
					},
					{
						Name: "",
						IsExempt: func(_ *models.User, _ *Warning) (bool, error) {
							return true, nil
						},
					},
				},
			}

			isExempt, err := warning.IsUserExempt(user)

			So(err, ShouldBeNil)
			So(isExempt, ShouldBeTrue)
		})

		Reset(func() {
			deleteUserWithUsername(user)
		})
	})
}

func TestAct(t *testing.T) {
	Convey("Given action", t, func() {
		Convey("Then it should call action function", func() {
			username := "actionuser"
			user, _, err := modeltesthelper.CreateUser(username)
			So(err, ShouldBeNil)

			var called = false

			warning := &Warning{
				Action: func(user *models.User, _ string) error {
					called = true
					return nil
				},
			}

			err = warning.Act(user)
			So(err, ShouldBeNil)
			So(called, ShouldBeTrue)

			Reset(func() {
				deleteUserWithUsername(user)
			})
		})
	})
}

func TestGetCount(t *testing.T) {
	Convey("It should return count", t, func() {
		user1, err := createInactiveUser(21)
		So(err, ShouldBeNil)

		user2, err := createInactiveUser(21)
		So(err, ShouldBeNil)

		warning := VMDeletionWarning1

		count, err := modelhelper.CountUsersByQuery(warning.buildSelectQuery())
		So(err, ShouldBeNil)

		So(count, ShouldEqual, 2)

		Convey("It should return minimum sleep", func() {
			sleepTime, err := warning.getSleepTime()
			So(err, ShouldBeNil)

			So(sleepTime, ShouldEqual, 20*time.Second)

			Reset(func() {
				deleteUserWithUsername(user1)
				deleteUserWithUsername(user2)
			})
		})
	})
}
