package main

import (
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"testing"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"

	. "github.com/smartystreets/goconvey/convey"
)

var (
	magicInstanceId = "i-ad086943"
	testUsername    = "test"
	usEastRegion    = "us-east-1"
)

func init() {
	initialize()
}

func TestRunningMachine(t *testing.T) {
	var machine *models.Machine

	Convey("Given running machine", t, func() {
		var err error

		machine, err = insertRunningMachine()
		So(err, ShouldBeNil)

		Convey("Then it should return the machine", func() {
			machines, err := getRunningVms()
			So(err, ShouldBeNil)

			So(len(machines), ShouldEqual, 1)
		})

		Reset(func() {
			removeUserMachine(testUsername)
		})
	})
}

func TestOverlimitMachines(t *testing.T) {
	var machine *models.Machine

	Convey("Given queued machine", t, func() {
		var err error

		machine, err = insertRunningMachine()
		So(err, ShouldBeNil)

		Convey("Then it should queue & pop the machine", func() {
			err := queueUsernamesForMetricGet()
			So(err, ShouldBeNil)

			queuedMachines, err := popMachinesForMetricGet(NetworkOut)
			So(err, ShouldBeNil)
			So(len(queuedMachines), ShouldEqual, 1)

			So(queuedMachines[0].Credential, ShouldEqual, machine.Credential)
		})

		Reset(func() {
			removeUserMachine(testUsername)
		})
	})
}

func TestStoppingMachines(t *testing.T) {
	var machine *models.Machine

	Convey("Given running machines that is over limit", t, func() {
		var err error

		machine, err = insertRunningMachine()
		So(err, ShouldBeNil)

		Convey("Then it should return machine", func() {
			networkOutMetric := metricsToSave[0]
			err := storage.SaveScore(networkOutMetric.GetName(), testUsername, NetworkOutLimit*3)
			So(err, ShouldBeNil)

			for _, metric := range metricsToSave {
				machines, err := metric.GetMachinesOverLimit(StopLimitKey)
				So(err, ShouldBeNil)

				So(len(machines), ShouldEqual, 1)
			}
		})

		Reset(func() {
			removeUserMachine(testUsername)
		})
	})
}

//----------------------------------------------------------
// Helpers
//----------------------------------------------------------

func insertRunningMachine() (*models.Machine, error) {
	user := &models.User{
		Name: testUsername, ObjectId: bson.NewObjectId(),
	}

	users := []models.MachineUser{
		models.MachineUser{
			Id: user.ObjectId, Sudo: true,
		},
	}

	modelhelper.CreateUser(user)

	machine := &models.Machine{
		ObjectId:   bson.NewObjectId(),
		Credential: user.Name,
		Meta: map[string]string{
			"instance_id": magicInstanceId, "region": usEastRegion,
		},
		Users:  users,
		Status: models.MachineStatus{State: modelhelper.MachineStateRunning},
	}

	return machine, modelhelper.CreateMachine(machine)
}

func removeUserMachine(username string) {
	modelhelper.RemoveUser(username)

	query := func(c *mgo.Collection) error {
		return c.Remove(bson.M{"credential": username})
	}

	modelhelper.Mongo.Run(modelhelper.MachinesColl, query)
}
