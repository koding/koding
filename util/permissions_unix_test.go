package util

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestIsAdmin(t *testing.T) {
	Convey("isAdmin", t, func() {
		Convey("Should return admin if response is 0", func() {
			admin, err := isAdmin("echo", "-n", "0")()
			So(err, ShouldBeNil)
			So(admin, ShouldBeTrue)
		})

		Convey("Should return not admin if response is not zero", func() {
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
