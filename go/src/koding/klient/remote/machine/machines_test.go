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

func TestMachinesAdd(t *testing.T) {
	Convey("Given a Machines struct", t, func() {
		ms := &Machines{}
		Convey("With a machine", func() {
			m := &Machine{
				MachineMeta: MachineMeta{
					Name: "foo",
					IP:   "bar",
					URL:  "http://bar",
				},
			}
			// Sanity check, make sure the machine is added
			So(ms.Add(m), ShouldBeNil)

			Convey("It should not allow the same machine to be added", func() {
				So(ms.Add(m), ShouldEqual, ErrMachineAlreadyAdded)
			})

			Convey("It should not allow a machine with the same name to be added", func() {
				similarM := &Machine{MachineMeta: MachineMeta{Name: "foo"}}
				So(ms.Add(similarM), ShouldEqual, ErrMachineDuplicate)
			})

			Convey("It should not allow a machine with the same ip to be added", func() {
				similarM := &Machine{MachineMeta: MachineMeta{IP: "bar"}}
				So(ms.Add(similarM), ShouldEqual, ErrMachineDuplicate)
			})

			Convey("It should not allow a machine with the same url to be added", func() {
				similarM := &Machine{MachineMeta: MachineMeta{URL: "http://bar"}}
				So(ms.Add(similarM), ShouldEqual, ErrMachineDuplicate)
			})
		})
	})
}
