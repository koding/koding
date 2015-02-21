package main

import (
	"koding/db/mongodb/modelhelper/modeltesthelper"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestEnvData(t *testing.T) {
	Convey("Given user has machines", t, func() {
		user, err := modeltesthelper.CreateUserWithMachine()
		So(err, ShouldBeNil)

		Convey("Then it should return machines", t, func() {
			envData, err := getEnvData(user.ObjectId)
			So(err, ShouldBeNil)

			own := envData.Own
			So(len(own), ShouldEqual, 1)
			So(len(own[0].Machine.Users), ShouldEqual, 1)

			machineUser := own[0].Machine.Users[0]
			So(machineUser.Id, ShouldEqual, user.ObjectId)

			Convey("Then it should be owner of machine", t, func() {
				So(machineUser.Id, ShouldEqual, user.ObjectId)
				So(machineUser.Owner, ShouldEqual, true)
			})
		})

		Convey("When user has workspaces", t, func() {
			Convey("Then it should return workspaces", t, func() {
			})
		})

		Reset(func() {
			modeltesthelper.DeleteUsersByUsername(user.Name)
		})
	})

	Convey("When user has shared machines", t, func() {
		Convey("Then it should return machines", t, func() {
		})

		Convey("When user has shared workspaces", t, func() {
			Convey("Then it should return workspaces", t, func() {
			})
		})
	})
}
