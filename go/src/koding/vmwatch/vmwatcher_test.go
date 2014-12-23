package main

import (
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"testing"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"

	. "github.com/smartystreets/goconvey/convey"
)

func TestRunningVms(t *testing.T) {
	Convey("Given running vm", t, func() {
		err := insertRunningMachine()
		So(err, ShouldBeNil)

		Convey("Then it should return the vm", func() {
			vms, err := getRunningVms()
			So(err, ShouldBeNil)

			So(len(vms), ShouldEqual, 1)
		})
	})
}

func insertRunningMachine() error {
	machine := models.Machine{ObjectId: bson.NewObjectId()}
	machine.Status.State = modelhelper.VmRunningState

	query := func(c *mgo.Collection) error {
		return c.Insert(machine)
	}

	return modelhelper.Mongo.Run(modelhelper.MachineColl, query)
}
