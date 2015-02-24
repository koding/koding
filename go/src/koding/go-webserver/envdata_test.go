package main

import (
	"koding/db/mongodb/modelhelper"
	"koding/db/mongodb/modelhelper/modeltesthelper"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestEnvData(t *testing.T) {
	Convey("Given user has machines", t, func() {
		username := "randomuser"

		user, err := modeltesthelper.CreateUserWithMachine(username)
		So(err, ShouldBeNil)

		envData := getEnvData(user)
		So(err, ShouldBeNil)

		own := envData.Own
		So(len(own), ShouldEqual, 1)

		machine := own[0].Machine
		So(machine, ShouldNotBeNil)

		workspaces := own[0].Workspaces
		So(len(workspaces), ShouldEqual, 1)

		Convey("Then it should return machines", func() {
			machines, err := modelhelper.GetMachines(user.ObjectId)
			So(err, ShouldBeNil)
			So(len(machines), ShouldEqual, 1)

			So(machines[0].ObjectId, ShouldEqual, machine.ObjectId)
		})

		Convey("Then it should return workspaces", func() {
			So(workspaces[0].MachineUID, ShouldEqual, machine.Uid)
		})

		Reset(func() {
			modeltesthelper.DeleteUsersByUsername(user.Name)
			modeltesthelper.DeleteMachine(machine.ObjectId)
			modeltesthelper.DeleteWorkspaceForMachine(machine.Uid)
		})
	})

	Convey("When user has shared machines", t, func() {
		username1 := "originaluser"
		_, err := modeltesthelper.CreateUserWithMachine(username1)
		So(err, ShouldBeNil)

		username2 := "shareduser"
		user, err := modeltesthelper.CreateUser(username2)
		So(err, ShouldBeNil)

		machines, err := modelhelper.GetMachinesByUsername(username1)
		So(len(machines), ShouldEqual, 1)
		So(err, ShouldBeNil)

		modeltesthelper.ShareMachineWithUser(machines[0].ObjectId, user.ObjectId)

		envData := getEnvData(user)
		So(err, ShouldBeNil)

		shared := envData.Shared
		So(len(shared), ShouldEqual, 1)

		machine := shared[0].Machine
		So(machine, ShouldNotBeNil)

		workspaces := shared[0].Workspaces
		So(len(workspaces), ShouldEqual, 1)

		Convey("Then it should return shared machines", func() {
			So(machines[0].ObjectId, ShouldEqual, machine.ObjectId)
		})

		Convey("Then it should return shared workspaces", func() {
			So(workspaces[0].MachineUID, ShouldEqual, machine.Uid)
		})

		Convey("Then it should have no own machines", func() {
			own := envData.Own
			So(len(own), ShouldEqual, 0)
		})

		Reset(func() {
			modeltesthelper.DeleteUsersByUsername(username1)
			modeltesthelper.DeleteUsersByUsername(username2)

			modeltesthelper.DeleteMachine(machine.ObjectId)
			modeltesthelper.DeleteWorkspaceForMachine(machine.Uid)
		})
	})
}
