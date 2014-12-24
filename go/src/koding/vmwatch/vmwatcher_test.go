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
	MagicInstanceId = "i-ad086943"
	USEastRegion    = "us-east-1"
)

func TestRunningVms(t *testing.T) {
	var machine *models.Machine

	Convey("Given running vm", t, func() {
		var err error

		machine, err = insertRunningMachine()
		So(err, ShouldBeNil)

		Convey("Then it should return the vm", func() {
			vms, err := getRunningVms()
			So(err, ShouldBeNil)

			So(len(vms), ShouldEqual, 1)
		})

		Reset(func() {
			removeMachine(machine)
		})
	})
}

func TestQueueRunningVms(t *testing.T) {
	var machine *models.Machine

	Convey("Given queued vm", t, func() {
		var err error

		machine, err = insertRunningMachine()
		So(err, ShouldBeNil)

		Convey("Then it should queue the vm", func() {
			err := queueUsernamesForMetricGet()
			So(err, ShouldBeNil)

			usernames, err := redisStorage.Client.GetSetMembers(redisStorage.QueueKey(NetworkOut))
			So(err, ShouldBeNil)

			So(len(usernames), ShouldEqual, 1)
			So((string(usernames[0].([]uint8))), ShouldEqual, machine.Credential)
		})

		Convey("Then it should pop the vm", func() {
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

func insertRunningMachine() (*models.Machine, error) {
	machine := &models.Machine{
		ObjectId:   bson.NewObjectId(),
		Meta:       bson.M{"instance_id": MagicInstanceId, "region": USEastRegion},
		Credential: "test",
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
