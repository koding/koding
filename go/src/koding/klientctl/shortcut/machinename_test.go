package shortcut

import (
	"koding/klient/remote/restypes"
	"koding/klientctl/list"
	"koding/klientctl/util/testutil"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestMachineShortcutGetNameFromShortcut(t *testing.T) {
	Convey("", t, func() {
		k := &testutil.FakeKlient{
			ReturnInfos: list.KiteInfos{
				list.KiteInfo{restypes.ListMachineInfo{VMName: "foo"}},
				list.KiteInfo{restypes.ListMachineInfo{VMName: "bar"}},
				list.KiteInfo{restypes.ListMachineInfo{VMName: "caz"}},
			},
		}
		ms := NewMachineShortcut(k)

		Convey("Given a full machine name", func() {
			Convey("It should return the full machine name", func() {
				name, err := ms.GetNameFromShortcut("bar")
				So(err, ShouldBeNil)
				So(name, ShouldEqual, "bar")
			})
		})

		Convey("Given a partial machine name", func() {
			Convey("It should return the full machine name", func() {
				name, err := ms.GetNameFromShortcut("b")
				So(err, ShouldBeNil)
				So(name, ShouldEqual, "bar")
			})
		})

		Convey("Given an invalid machine name", func() {
			Convey("It should return ErrMachineNotFound", func() {
				_, err := ms.GetNameFromShortcut("idontexist")
				So(err, ShouldEqual, ErrMachineNotFound)
			})
		})
	})
}
