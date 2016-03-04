package repair

import (
	"io/ioutil"
	"koding/klient/remote/req"
	"koding/klientctl/util"
	"koding/klientctl/util/testutil"
	"os"
	"path/filepath"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestPermDeniedRepair(t *testing.T) {
	Convey("Given the mount dir has 655 perms", t, func() {
		tmpDir, err := ioutil.TempDir("", "permdeniedrepair")
		So(err, ShouldBeNil)
		defer os.RemoveAll(tmpDir)

		permDir := filepath.Join(tmpDir, "dir")

		// Make the perm denied dir.. as best we can replicate.
		err = os.Mkdir(permDir, 0655)
		So(err, ShouldBeNil)

		fakeKlient := &testutil.FakeKlient{
			ReturnMountInfo: req.MountInfoResponse{
				MountFolder: req.MountFolder{
					LocalPath: permDir,
				},
			},
		}

		r := &PermDeniedRepair{
			Log:    discardLogger,
			Stdout: util.NewFprint(ioutil.Discard),
			Klient: fakeKlient,
		}

		Convey("When Status is run", func() {
			Convey("It should return a mount permission error", func() {
				err := r.Status()
				So(err, ShouldNotBeNil)
				So(err.Error(), ShouldContainSubstring, "wrong permission")
			})
		})

		Convey("When Repair is run", func() {
			Convey("It should call RemoteRemount", func() {
				// Ignoring error here, because Repair will simply return that the dir
				// still has 655. Because it does.
				r.Repair()
				So(fakeKlient.GetCallCount("RemoteRemount"), ShouldEqual, 1)
			})

			Convey("It should check the status of the mount again", func() {
				err := r.Repair()
				So(err, ShouldNotBeNil)
				So(err.Error(), ShouldContainSubstring, "wrong permission")
			})
		})
	})

	Convey("Given the mount dir does not have 655 perms", t, func() {
		tmpDir, err := ioutil.TempDir("", "permdeniedrepair")
		So(err, ShouldBeNil)
		defer os.RemoveAll(tmpDir)

		permDir := filepath.Join(tmpDir, "dir")

		// Make the perm denied dir.. as best we can replicate.
		err = os.Mkdir(permDir, 0755)
		So(err, ShouldBeNil)

		fakeKlient := &testutil.FakeKlient{
			ReturnMountInfo: req.MountInfoResponse{
				MountFolder: req.MountFolder{
					LocalPath: permDir,
				},
			},
		}

		r := &PermDeniedRepair{
			Log:    discardLogger,
			Stdout: util.NewFprint(ioutil.Discard),
			Klient: fakeKlient,
		}

		Convey("When Status is run", func() {
			Convey("It should return no error", func() {
				err := r.Status()
				So(err, ShouldBeNil)
			})
		})
	})
}
