package repair

import (
	"io/ioutil"
	"koding/klientctl/util"
	"koding/klientctl/util/testutil"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestMountExistsRepair(t *testing.T) {
	Convey("Given fs mount and klient mount exist", t, func() {
		r := &MountExistsRepair{
			Log:      discardLogger,
			Stdout:   util.NewFprint(ioutil.Discard),
			Klient:   &testutil.FakeKlient{},
			Mountcli: &testutil.FakeMountcli{ReturnMountByPath: "foo/bar"},
		}

		Convey("When Status is run", func() {
			Convey("It should not return an error", func() {
				err := r.Status()
				So(err, ShouldBeNil)
			})
		})
	})

	Convey("Given klient mount exists but fs mount does not", t, func() {
		r := &MountExistsRepair{
			Log:      discardLogger,
			Stdout:   util.NewFprint(ioutil.Discard),
			Klient:   &testutil.FakeKlient{},
			Mountcli: &testutil.FakeMountcli{},
		}

		Convey("When Status is run", func() {
			Convey("It should return an error", func() {
				err := r.Status()
				So(err, ShouldNotBeNil)
			})
		})
	})
}
