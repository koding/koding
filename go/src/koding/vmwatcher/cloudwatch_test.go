package main

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestCloudwatch(t *testing.T) {
	// Convey("Given a vm", t, func() {
	//   machine, err := insertRunningMachine()
	//   So(err, ShouldBeNil)

	//   Convey("Then it should save cloudwatch data", func() {
	//     c := Cloudwatch{Name: NetworkOut}
	//     err := c.GetAndSaveData(machine.Credential)

	//     So(err, ShouldBeNil)
	//   })

	//   Reset(func() {
	//     removeMachine(machine)
	//   })
	// })

	Convey("Given user", t, func() {
		var networkOutMetric, username = metricsToSave[0], "indianajones"

		Convey("When user is overlimit", func() {
			Convey("Then it should save value", func() {
				var value float64 = NetworkOutLimit * PaidPlanMultiplier * 2

				err := networkOutMetric.Save(username, value)
				So(err, ShouldBeNil)

				Convey("Then it return if user is overlimit", func() {
					lr, err := networkOutMetric.IsUserOverLimit(username)
					So(err, ShouldBeNil)

					So(lr.CanStart, ShouldBeFalse)
				})
			})
		})

		Convey("When user is underlimit", func() {
			Convey("Then it should save value", func() {
				var value float64 = NetworkOutLimit - 100

				err := networkOutMetric.Save(username, value)
				So(err, ShouldBeNil)

				Convey("Then it return if user is overlimit", func() {
					lr, err := networkOutMetric.IsUserOverLimit(username)
					So(err, ShouldBeNil)

					So(lr.CanStart, ShouldBeTrue)
				})
			})
		})
	})
}
