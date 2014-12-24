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
			removeMachine(machine)
		})
	})
}

func TestOverlimitMachines(t *testing.T) {
	var machine *models.Machine

	Convey("Given queued machine", t, func() {
		var err error

		machine, err = insertRunningMachine()
		So(err, ShouldBeNil)

		Convey("Then it should queue the machine", func() {
			err := queueUsernamesForMetricGet()
			So(err, ShouldBeNil)

			usernames, err := redisStorage.Client.GetSetMembers(redisStorage.QueueKey(NetworkOut))
			So(err, ShouldBeNil)

			So(len(usernames), ShouldEqual, 1)
			So((string(usernames[0].([]uint8))), ShouldEqual, machine.Credential)
		})

		Convey("Then it should pop the machine", func() {
			queuedMachines, err := popMachinesForMetricGet()
			So(err, ShouldBeNil)
			So(len(queuedMachines), ShouldEqual, 1)

			So(queuedMachines[0].Credential, ShouldEqual, machine.Credential)
		})

		Reset(func() {
			removeMachine(machine)
		})
	})
}

func TestStoppingMachines(t *testing.T) {
	var machine *models.Machine

	Convey("Given running machines that is over limit", t, func() {
		var err error

		machine, err = insertRunningMachine()
		So(err, ShouldBeNil)

		err = queueUsernamesForMetricGet()
		So(err, ShouldBeNil)

		Convey("Then it should return machine", func() {
			for _, metric := range metricsToSave {
				machines, err := metric.GetMachinesOverLimit()
				So(err, ShouldBeNil)

				So(len(machines), ShouldEqual, 1)
			}
		})

		Reset(func() {
			removeMachine(machine)
		})
	})
}

func insertRunningMachine() (*models.Machine, error) {
	machine := &models.Machine{
		ObjectId:   bson.NewObjectId(),
		Meta:       bson.M{"instance_id": magicInstanceId, "region": usEastRegion},
		Credential: testUsername,
	}

	machine.Status.State = modelhelper.VmRunningState

	query := func(c *mgo.Collection) error {
		return c.Insert(machine)
	}

	return machine, modelhelper.Mongo.Run(modelhelper.MachineColl, query)
}

func removeMachine(machine *models.Machine) {
	query := func(c *mgo.Collection) error {
		return c.Remove(bson.M{"_id": machine.ObjectId})
	}

	modelhelper.Mongo.Run(modelhelper.MachineColl, query)
}
