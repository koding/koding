package repair

import (
	"io"
	"io/ioutil"
	"koding/klient/command"
	"koding/klient/remote/req"
	"koding/klientctl/util"
	"koding/klientctl/util/testutil"
	"os"
	"path/filepath"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestWriteReadRepair(t *testing.T) {
	Convey("Given a WriteReadRepair", t, func() {
		mountDir, err := ioutil.TempDir("", "writereadrepair")
		So(err, ShouldBeNil)
		defer os.RemoveAll(mountDir)

		fakeKlient := &testutil.FakeKlient{}
		r := &WriteReadRepair{
			Log:    discardLogger,
			Stdout: util.NewFprint(ioutil.Discard),
			Klient: fakeKlient,
		}

		Convey("When a directory that can be written to", func() {
			fakeKlient.ReturnMountInfo = req.MountInfoResponse{
				MountFolder: req.MountFolder{
					LocalPath: mountDir,
				},
			}
			fakeKlient.ReturnRemoteExec = command.Output{Stdout: testFileContent}

			Convey("When Status() is called", func() {
				Convey("It should return okay", func() {
					ok, err := r.Status()
					So(err, ShouldBeNil)
					So(ok, ShouldBeTrue)
				})

				Convey("It should not remove the MountDir", func() {
					r.Status()
					exists, err := doesDirExists(mountDir)
					So(err, ShouldBeNil)
					So(exists, ShouldBeTrue)
				})

				Convey("It should cleanup the test dir after it's done", func() {
					r.Status()
					// The mount dir should be empty, just like it started with
					empty, err := isDirEmpty(mountDir)
					So(err, ShouldBeNil)
					So(empty, ShouldBeTrue)
				})
			})
		})

		Convey("When a directory that cannot be written to", func() {
			notExistDir := filepath.Join(mountDir, "i", "dont", "exist")
			fakeKlient.ReturnMountInfo = req.MountInfoResponse{
				MountFolder: req.MountFolder{
					LocalPath: notExistDir,
				},
			}

			Convey("When Status() is called", func() {
				Convey("It should return not-okay", func() {
					ok, err := r.Status()
					So(err, ShouldBeNil)
					So(ok, ShouldBeFalse)
				})

				Convey("It should not remove the MountDir", func() {
					r.Status()
					exists, err := doesDirExists(mountDir)
					So(err, ShouldBeNil)
					So(exists, ShouldBeTrue)
				})

				Convey("It should cleanup the test dir after it's done", func() {
					r.Status()
					// The mount dir should be empty, just like it started with
					empty, err := isDirEmpty(mountDir)
					So(err, ShouldBeNil)
					So(empty, ShouldBeTrue)
				})
			})

			Convey("When Repair() is called", func() {
				Convey("It should call RemoteRemount", func() {
					r.Repair()
					So(fakeKlient.GetCallCount("RemoteRemount"), ShouldEqual, 1)
				})

				Convey("It should run status again", func() {
					r.Repair()
					// Checking if Status was called is a bit difficult, so we are
					// instead checking if MountInfo is called - which is only called
					// from status at the moment.
					So(fakeKlient.GetCallCount("RemoteMountInfo"), ShouldEqual, 1)
				})
			})
		})

		Convey("When the remote file does not exist", func() {
			fakeKlient.ReturnMountInfo = req.MountInfoResponse{
				MountFolder: req.MountFolder{
					LocalPath: mountDir,
				},
			}
			fakeKlient.ReturnRemoteExec = command.Output{ExitStatus: 1}

			Convey("When Status() is called", func() {
				Convey("It should return not okay", func() {
					ok, err := r.Status()
					So(err, ShouldBeNil)
					So(ok, ShouldBeFalse)
				})

				Convey("It should not remove the MountDir", func() {
					r.Status()
					exists, err := doesDirExists(mountDir)
					So(err, ShouldBeNil)
					So(exists, ShouldBeTrue)
				})

				Convey("It should cleanup the test dir after it's done", func() {
					r.Status()
					// The mount dir should be empty, just like it started with
					empty, err := isDirEmpty(mountDir)
					So(err, ShouldBeNil)
					So(empty, ShouldBeTrue)
				})
			})
		})

		Convey("When the remote files contents do not match", func() {
			fakeKlient.ReturnMountInfo = req.MountInfoResponse{
				MountFolder: req.MountFolder{
					LocalPath: mountDir,
				},
			}
			fakeKlient.ReturnRemoteExec = command.Output{Stdout: "badcontents"}

			Convey("When Status() is called", func() {
				Convey("It should return not okay", func() {
					ok, err := r.Status()
					So(err, ShouldBeNil)
					So(ok, ShouldBeFalse)
				})

				Convey("It should not remove the MountDir", func() {
					r.Status()
					exists, err := doesDirExists(mountDir)
					So(err, ShouldBeNil)
					So(exists, ShouldBeTrue)
				})

				Convey("It should cleanup the test dir after it's done", func() {
					r.Status()
					// The mount dir should be empty, just like it started with
					empty, err := isDirEmpty(mountDir)
					So(err, ShouldBeNil)
					So(empty, ShouldBeTrue)
				})
			})
		})
	})
}

func isDirEmpty(p string) (bool, error) {
	f, err := os.Open(p)
	if err != nil {
		return false, err
	}
	defer f.Close()

	if _, err = f.Readdirnames(1); err == io.EOF {
		return true, nil
	}

	return false, err
}

func doesDirExists(p string) (bool, error) {
	_, err := os.Stat(p)
	switch {
	case err == nil:
		return true, nil
	case os.IsNotExist(err):
		return false, nil
	default:
		return false, err
	}
}
