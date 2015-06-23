package main

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestQueueUsernamesForMetricsGet(t *testing.T) {
	Convey("Given running machine", t, func() {
		machine, err := insertRunningMachine()
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
			removeUserMachine(machine.Credential)
		})
	})
}

func TestQueueOverLimitUsers(t *testing.T) {
	Convey("Given users that are overlimit", t, func() {
		machine, err := insertRunningMachine()
		So(err, ShouldBeNil)

		Convey("Then it should queue machine for stopping", func() {
			networkOutMetric := metricsToSave[0]
			err := storage.SaveScore(networkOutMetric.GetName(), machine.Credential, NetworkOutLimit*5)
			So(err, ShouldBeNil)

			queueOverlimitUsers()

			Convey("Then it should pop machine", func() {
				queuedMachines, err := popMachinesOverLimit(NetworkOut, StopLimitKey)
				So(err, ShouldBeNil)
				So(len(queuedMachines), ShouldEqual, 1)

				So(queuedMachines[0].Credential, ShouldEqual, machine.Credential)
			})
		})

		Reset(func() {
			removeUserMachine(machine.Credential)
		})
	})
}
