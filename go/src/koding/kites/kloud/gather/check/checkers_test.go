package main

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestBinData(t *testing.T) {
	Convey("It should access assets in bindata", t, func() {
		common, err := Asset("checkers/common")
		So(err, ShouldBeNil)

		result, err := runScript(common, "checkers/run-poi")
		So(err, ShouldBeNil)

		So(result.Type, ShouldEqual, "boolean")
		So(result.Name, ShouldEqual, "postgresql installed")
		So(result.Error, ShouldEqual, "")
	})
}
