package repair

import (
	"io/ioutil"
	"koding/klientctl/util"
	"koding/klientctl/util/testutil"
	"koding/mountcli"
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
			Convey("It should okay", func() {
				ok, err := r.Status()
				So(ok, ShouldBeTrue)
				So(err, ShouldBeNil)
			})
		})
	})

	Convey("Given klient mount exists but fs mount does not", t, func() {
		r := &MountExistsRepair{
			Log:    discardLogger,
			Stdout: util.NewFprint(ioutil.Discard),
			Klient: &testutil.FakeKlient{},
			Mountcli: &testutil.FakeMountcli{
				ReturnMountByPathErr: mountcli.ErrNoMountName,
			},
		}

		Convey("When Status is run", func() {
			Convey("It should return an error", func() {
				ok, err := r.Status()
				So(ok, ShouldBeFalse)
				So(err, ShouldBeNil)
			})
		})
	})
}
