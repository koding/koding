package main

import (
	"koding/db/mongodb/modelhelper/modeltesthelper"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestCloudwatchFree(t *testing.T) {
	Convey("", t, func() {
		url, server := buildPaymentServer("free")
		PlanUrl = url

		defer server.Close()

		username := "indianajones"
		_, _, err := modeltesthelper.CreateUser(username)
		So(err, ShouldBeNil)

		defer removeUser(username)

		var networkOutMetric = metricsToSave[0]

		Convey("When user is overlimit than free plan", func() {
			var value float64 = NetworkOutLimit * PaidPlanMultiplier * 2

			err := networkOutMetric.Save(username, value)
			So(err, ShouldBeNil)

			Convey("Then they can't start their machine", func() {
				lr, err := networkOutMetric.IsUserOverLimit(username, StopLimitKey)
				So(err, ShouldBeNil)

				So(lr.CanStart, ShouldBeFalse)
			})
		})

		Convey("When user is underlimit than free plan", func() {
			var value float64 = NetworkOutLimit - 100

			err := networkOutMetric.Save(username, value)
			So(err, ShouldBeNil)

			Convey("Then they can start their machine", func() {
				lr, err := networkOutMetric.IsUserOverLimit(username, StopLimitKey)
				So(err, ShouldBeNil)

				So(lr.CanStart, ShouldBeTrue)
			})
		})
	})
}

func TestCloudwatchPaid(t *testing.T) {
	Convey("", t, func() {
		url, server := buildPaymentServer("hobbyist")
		PlanUrl = url

		defer server.Close()

		username := "indianajones"
		_, _, err := modeltesthelper.CreateUser(username)
		So(err, ShouldBeNil)

		defer removeUser(username)
		var networkOutMetric = metricsToSave[0]

		Convey("When user is overlimit than paid plan", func() {
			var value float64 = NetworkOutLimit * PaidPlanMultiplier * 2

			err := networkOutMetric.Save(username, value)
			So(err, ShouldBeNil)

			Convey("Then they can't start their machine", func() {
				lr, err := networkOutMetric.IsUserOverLimit(username, StopLimitKey)
				So(err, ShouldBeNil)

				So(lr.CanStart, ShouldBeFalse)
			})
		})

		Convey("When user is underlimit than free plan", func() {
			var value float64 = (NetworkOutLimit * PaidPlanMultiplier) - 100

			err := networkOutMetric.Save(username, value)
			So(err, ShouldBeNil)

			Convey("Then they can start their machine", func() {
				lr, err := networkOutMetric.IsUserOverLimit(username, StopLimitKey)
				So(err, ShouldBeNil)

				So(lr.CanStart, ShouldBeTrue)
			})
		})
	})
}

func TestCloudwatchPerUser(t *testing.T) {
	Convey("", t, func() {
		url, server := buildPaymentServer("free")
		PlanUrl = url

		defer server.Close()

		username := "indianajones"
		_, _, err := modeltesthelper.CreateUser(username)
		So(err, ShouldBeNil)

		defer removeUser(username)

		var networkOutMetric = metricsToSave[0]

		Convey("When user is overlimit than their specified limit", func() {
			var value float64 = NetworkOutLimit

			err := networkOutMetric.Save(username, value)
			So(err, ShouldBeNil)

			err = saveUserLimit(username, value-1)
			So(err, ShouldBeNil)

			Convey("Then they can't start their machine", func() {
				lr, err := networkOutMetric.IsUserOverLimit(username, StopLimitKey)
				So(err, ShouldBeNil)

				So(lr.CanStart, ShouldBeFalse)
			})
		})

		Convey("When user is underlimit than their specified limit", func() {
			var value float64 = NetworkOutLimit

			err := networkOutMetric.Save(username, value)
			So(err, ShouldBeNil)

			err = saveUserLimit(username, value+1)
			So(err, ShouldBeNil)

			Convey("Then they can start their machine", func() {
				lr, err := networkOutMetric.IsUserOverLimit(username, StopLimitKey)
				So(err, ShouldBeNil)

				So(lr.CanStart, ShouldBeTrue)
			})
		})
	})
}

func removeUser(username string) {
	modeltesthelper.DeleteUsersByUsername(username)
	storage.RemoveUserLimit(username)
}
