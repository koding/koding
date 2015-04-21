package main

import (
	"fmt"
	"koding/db/models"
	"testing"
	"time"

	"labix.org/v2/mgo/bson"

	. "github.com/smartystreets/goconvey/convey"
)

func TestReleaseUser(t *testing.T) {
	Convey("Given user", t, func() {
		level := 9001

		user, err := createUserWithWarning(level-1, yesterday())
		So(err, ShouldBeNil)

		warning := &Warning{
			Select: bson.M{"username": user.Name, "inactive.warning": level - 1},
			Level:  level,
		}

		_, err = warning.FindAndLockUser()
		So(err, ShouldBeNil)

		Convey("When it releases user", func() {
			err = warning.ReleaseUser(user.ObjectId)
			So(err, ShouldBeNil)

			Convey("Then it updates modifiedAt", func() {
				updatedUser, err := findUser(user.Name)
				So(err, ShouldBeNil)

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
		level := 9001

		user, err := createUserWithWarning(level-1, yesterday())
		So(err, ShouldBeNil)

		warning := &Warning{
			Select: bson.M{"username": user.Name, "inactive.warning": level - 1},
			Level:  level,
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
				Exempt: []Exempt{func(_ *models.User, _ *Warning) (bool, error) {
					return true, nil
				}},
			}

			isExempt, err := warning.IsUserExempt(user)

			So(err, ShouldBeNil)
			So(isExempt, ShouldBeTrue)
		})

		Convey("Then it should not be exempt", func() {
			warning := &Warning{
				Exempt: []Exempt{func(_ *models.User, _ *Warning) (bool, error) {
					return false, nil
				}},
			}

			isExempt, err := warning.IsUserExempt(user)

			So(err, ShouldBeNil)
			So(isExempt, ShouldBeFalse)
		})

		Convey("Then it should be exempt even if one condition is exempt", func() {
			warning := &Warning{
				Exempt: []Exempt{
					func(_ *models.User, _ *Warning) (bool, error) { return false, nil },
					func(_ *models.User, _ *Warning) (bool, error) { return true, nil },
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
		Convey("Then it should call it if not exempt", func() {
			user, err := createUser()
			So(err, ShouldBeNil)

			var called = false

			warning := &Warning{
				Action: func(user *models.User, level int) error {
					called = true
					return nil
				},

				Exempt: []Exempt{func(user *models.User, _ *Warning) (bool, error) {
					return false, nil
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

				Exempt: []Exempt{func(_ *models.User, _ *Warning) (bool, error) {
					return true, nil
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

func updateModifiedAt(user *models.User, m time.Time) {
}
