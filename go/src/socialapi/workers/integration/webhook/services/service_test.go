package services

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestServiceInput(t *testing.T) {
	Convey("while testing service input", t, func() {
		Convey("it should return nil when key does not exist", func() {
			si := ServiceInput{}
			val := si.Key("hey")
			So(val, ShouldBeNil)
		})

		Convey("it should return value when key does exist", func() {
			si := ServiceInput{}
			si["electric"] = "mayhem"
			val := si.Key("electric")
			So(val.(string), ShouldEqual, "mayhem")
		})

		Convey("it should be able to add new values", func() {
			si := ServiceInput{}
			si.SetKey("electric", "mayhem")
			val, ok := si["electric"]
			So(ok, ShouldEqual, true)
			So(val.(string), ShouldEqual, "mayhem")
		})
	})
}
