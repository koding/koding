package main

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestCloudwatch(t *testing.T) {
	Convey("Given a vm", t, func() {
		machine, err := insertRunningMachine()
		So(err, ShouldBeNil)

		Convey("Then it should save cloudwatch data", func() {
			c := Cloudwatch{Name: NetworkOut}
			err := c.GetAndSaveData(machine.Credential)

			So(err, ShouldBeNil)
		})

		Reset(func() {
			removeMachine(machine)
		})
	})
}
