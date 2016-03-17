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

func TestMountEmptyRepair(t *testing.T) {
	Convey("Given the mount path is empty", t, func() {
		tmpDir, err := ioutil.TempDir("", "mountemptyrepair")
		So(err, ShouldBeNil)
		defer os.RemoveAll(tmpDir)

		fakeKlient := &testutil.FakeKlient{
			ReturnMountInfo: req.MountInfoResponse{
				MountFolder: req.MountFolder{
					LocalPath: tmpDir,
				},
			},
		}

		r := &MountEmptyRepair{
			Log:    discardLogger,
			Stdout: util.NewFprint(ioutil.Discard),
			Klient: fakeKlient,
		}

		Convey("When Status is run", func() {
			Convey("It should be not okay", func() {
				ok, err := r.Status()
				So(ok, ShouldBeFalse)
				So(err, ShouldBeNil)
			})
		})

		Convey("When Repair is run", func() {
			Convey("It should call RemoteRemount", func() {
				// Ignoring error here, because Repair will simply return that the dir
				// is still empty. Because it is.
				r.Repair()
				So(fakeKlient.GetCallCount("RemoteRemount"), ShouldEqual, 1)
			})

			Convey("It should check the status of the mount again", func() {
				err := r.Repair()
				So(err, ShouldNotBeNil)
				So(err.Error(), ShouldContainSubstring, "not-okay")
			})
		})
	})

	Convey("Given the mount path is not empty", t, func() {
		tmpDir, err := ioutil.TempDir("", "mountemptyrepair")
		So(err, ShouldBeNil)
		defer os.RemoveAll(tmpDir)

		fakeKlient := &testutil.FakeKlient{
			ReturnMountInfo: req.MountInfoResponse{
				MountFolder: req.MountFolder{
					LocalPath: tmpDir,
				},
			},
		}

		r := &MountEmptyRepair{
			Log:    discardLogger,
			Stdout: util.NewFprint(ioutil.Discard),
			Klient: fakeKlient,
		}

		Convey("With a file", func() {
			f, err := os.Create(filepath.Join(tmpDir, "file"))
			So(err, ShouldBeNil)
			f.Close()

			Convey("When Status is run", func() {
				Convey("It should return okay", func() {
					ok, err := r.Status()
					So(ok, ShouldBeTrue)
					So(err, ShouldBeNil)
				})
			})
		})

		Convey("With a dir", func() {
			So(os.Mkdir(filepath.Join(tmpDir, "dir"), 0755), ShouldBeNil)

			Convey("When Status is run", func() {
				Convey("It should not return an error", func() {
					ok, err := r.Status()
					So(ok, ShouldBeTrue)
					So(err, ShouldBeNil)
				})
			})
		})
	})
}
