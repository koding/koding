package machine

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestGetByURL(t *testing.T) {
	Convey("Given a Machines struct", t, func() {
		fooMachine := &Machine{MachineMeta: MachineMeta{URL: "http://foo.url"}}
		ms := Machines{machines: []*Machine{fooMachine}}

		Convey("With a URL that matches a machine", func() {
			Convey("It should return the machine", func() {
				m, err := ms.GetByURL("http://foo.url")
				So(err, ShouldBeNil)
				So(m, ShouldEqual, fooMachine)
			})
		})

		Convey("With a URL that does not matche a machine", func() {
			Convey("It should return ErrMachineNotFound", func() {
				m, err := ms.GetByURL("http://different.url")
				So(err, ShouldEqual, ErrMachineNotFound)
				So(m, ShouldBeNil)

				m, err = ms.GetByURL("http://foo.url/different/path")
				So(err, ShouldEqual, ErrMachineNotFound)
				So(m, ShouldBeNil)
			})
		})
	})
}
