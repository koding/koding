package main

import (
	"fmt"
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
