package gather

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestScriptRun(t *testing.T) {
	Convey("It should run script using bash", t, func() {
		s := &Script{Path: "test-scripts/run-ls"}

		result, err := s.Run()
		So(err, ShouldBeNil)

		So(result, ShouldNotBeNil)
		So(result.Name, ShouldEqual, "test script")
		So(result.Type, ShouldEqual, "bool")
	})
}
