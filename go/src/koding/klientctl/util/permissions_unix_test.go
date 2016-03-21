package util

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func genBinRunner(output string, err error) binRunner {
	return func(string, ...string) ([]byte, error) {
		return []byte(output), err
	}
}

func TestIsAdmin(t *testing.T) {
	Convey("Given the bin response is 0", t, func() {
		p := Permissions{binRunner: genBinRunner("0", nil)}

		Convey("Then the user is admin", func() {
			admin, err := p.IsAdmin()
			So(err, ShouldBeNil)
			So(admin, ShouldBeTrue)
		})
	})

	Convey("Given the bin response is not 0", t, func() {
		p := Permissions{}

		Convey("Then the user is not an admin", func() {
			p.binRunner = genBinRunner("501", nil)
			admin, err := p.IsAdmin()
			So(err, ShouldBeNil)
			So(admin, ShouldBeFalse)

			p.binRunner = genBinRunner("-1", nil)
			admin, err = p.IsAdmin()
			So(err, ShouldBeNil)
			So(admin, ShouldBeFalse)

			p.binRunner = genBinRunner("01", nil)
			admin, err = p.IsAdmin()
			So(err, ShouldBeNil)
			So(admin, ShouldBeFalse)
		})
	})

	Convey("Given the bin response ends in whitespace", t, func() {
		p := Permissions{}

		Convey("Then it should still respond properly", func() {
			p.binRunner = genBinRunner("0\n", nil)
			admin, err := p.IsAdmin()
			So(err, ShouldBeNil)
			So(admin, ShouldBeTrue)

			p.binRunner = genBinRunner("  \n0  \n ", nil)
			admin, err = p.IsAdmin()
			So(err, ShouldBeNil)
			So(admin, ShouldBeTrue)

			p.binRunner = genBinRunner(" 501 \n", nil)
			admin, err = p.IsAdmin()
			So(err, ShouldBeNil)
			So(admin, ShouldBeFalse)
		})
	})
}
