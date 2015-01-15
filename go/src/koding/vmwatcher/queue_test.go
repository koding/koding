package main

import (
	"koding/db/models"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestQueueUsernamesForMetricsGet(t *testing.T) {
	var machine *models.Machine

	Convey("Given running machine", t, func() {
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
