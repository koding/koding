package main

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"koding/db/mongodb/modelhelper/modeltesthelper"
	"net/http"
	"net/http/httptest"
	"net/url"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestEnvDataOwn(t *testing.T) {
	Convey("Given user has machines", t, func() {
		username := "randomuser"

		user, err := modeltesthelper.CreateUserWithMachine(username)
		So(err, ShouldBeNil)

		userInfo := &UserInfo{UserId: user.ObjectId, SocialApiId: "1"}
		envData := getEnvData(userInfo)

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
}

func TestEnvDataShared(t *testing.T) {
	Convey("When user has shared machines", t, func() {
		username1 := "originaluser"
		user1, err := modeltesthelper.CreateUserWithMachine(username1)
		So(err, ShouldBeNil)

		_, err = modeltesthelper.CreateMachineForUser(user1.ObjectId)
		So(err, ShouldBeNil)

		username2 := "shareduser"
		user, err := modeltesthelper.CreateUserWithMachine(username2)
		So(err, ShouldBeNil)

		machines, err := modelhelper.GetMachinesByUsername(username1)
		So(len(machines), ShouldEqual, 2)
		So(err, ShouldBeNil)

		modeltesthelper.ShareMachineWithUser(machines[0].ObjectId,
			user.ObjectId, true)

		userInfo := &UserInfo{UserId: user.ObjectId, SocialApiId: "1"}
		envData := getEnvData(userInfo)

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

		Convey("Then it should have one own machines", func() {
			So(len(envData.Own), ShouldEqual, 1)
		})

		Convey("Then it should have no collab machines", func() {
			So(len(envData.Collaboration), ShouldEqual, 0)
		})

		Reset(func() {
			modeltesthelper.DeleteUsersAndMachines(username1)
			modeltesthelper.DeleteUsersAndMachines(username2)

			modeltesthelper.DeleteMachine(machine.ObjectId)
			modeltesthelper.DeleteWorkspaceForMachine(machine.Uid)
		})
	})
}

func TestEnvDataCollab(t *testing.T) {
	workspaceChannelId := "5923709740252136379"

	mux := http.NewServeMux()
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprint(w, `[{"channel":{"id":"5923709740252136379"}}]`)
	})

	server := httptest.NewServer(mux)
	url, _ := url.Parse(server.URL)

	defer server.Close()

	conf.SocialApi.ProxyUrl = url.String()

	Convey("When user has shared machines", t, func() {
		username1 := "originaluser"
		_, err := modeltesthelper.CreateUserWithMachine(username1)
		So(err, ShouldBeNil)

		username2 := "shareduser"
		user, _, err := modeltesthelper.CreateUser(username2)
		So(err, ShouldBeNil)

		machines, err := modelhelper.GetMachinesByUsername(username1)
		So(len(machines), ShouldEqual, 1)
		So(err, ShouldBeNil)

		modeltesthelper.ShareMachineWithUser(machines[0].ObjectId,
			user.ObjectId, false)

		account, err := modelhelper.GetAccount(username1)
		So(err, ShouldBeNil)

		err = modeltesthelper.UpdateAccountSocialApiId(account.Id, "1")
		So(err, ShouldBeNil)

		err = modeltesthelper.UpdateWorkspaceChannelId(machines[0].Uid, workspaceChannelId)
		So(err, ShouldBeNil)

		userInfo := &UserInfo{UserId: user.ObjectId, SocialApiId: "1"}
		envData := getEnvData(userInfo)

		collab := envData.Collaboration
		So(len(collab), ShouldEqual, 1)

		machine := collab[0].Machine
		So(machine, ShouldNotBeNil)

		workspaces := collab[0].Workspaces
		So(len(workspaces), ShouldEqual, 1)

		Convey("Then it should return collab machines", func() {
			So(machines[0].ObjectId, ShouldEqual, machine.ObjectId)
		})

		Convey("Then it should return collab workspaces", func() {
			So(workspaces[0].MachineUID, ShouldEqual, machine.Uid)
		})

		Convey("Then it should have no own machines", func() {
			So(len(envData.Own), ShouldEqual, 0)
		})

		Convey("Then it should have no shared machines", func() {
			So(len(envData.Shared), ShouldEqual, 0)
		})

		Reset(func() {
			modeltesthelper.DeleteUsersAndMachines(username1)
			modeltesthelper.DeleteUsersAndMachines(username2)

			modeltesthelper.DeleteMachine(machine.ObjectId)
			modeltesthelper.DeleteWorkspaceForMachine(machine.Uid)
		})
	})
}
