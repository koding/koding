package util

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestIsAdmin(t *testing.T) {
	Convey("Given the bin response is 0", t, func() {
		Convey("Then the user is admin", func() {
			admin, err := isAdmin("echo", "-n", "0")()
			So(err, ShouldBeNil)
			So(admin, ShouldBeTrue)
		})
	})

	Convey("Given the bin response is not 0", t, func() {
		Convey("Then the user is not an admin", func() {
			admin, err := isAdmin("echo", "-n", "501")()
			So(err, ShouldBeNil)
			So(admin, ShouldBeFalse)
			admin, err = isAdmin("echo", "-n", "-1")()
			So(err, ShouldBeNil)
			So(admin, ShouldBeFalse)
			admin, err = isAdmin("echo", "-n", "01")()
			So(err, ShouldBeNil)
			So(admin, ShouldBeFalse)
		})
	})
}
