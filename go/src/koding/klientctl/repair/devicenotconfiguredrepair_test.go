package repair

import (
	"errors"
	"io/ioutil"
	"koding/fuseklient"
	"koding/klient/remote/req"
	"koding/klientctl/util"
	"koding/klientctl/util/testutil"
	"os"
	"path/filepath"
	"testing"
	"time"

	"golang.org/x/net/context"

	"github.com/jacobsa/fuse"
	"github.com/jacobsa/fuse/fuseops"
	"github.com/jacobsa/fuse/fuseutil"
	. "github.com/smartystreets/goconvey/convey"
)

type NotImplementedFileSystem struct {
	*fuseutil.NotImplementedFileSystem
}

func (niFs *NotImplementedFileSystem) StatFS(ctx context.Context, op *fuseops.StatFSOp) error {
	return nil
}

func (niFs *NotImplementedFileSystem) LookUpInode(ctx context.Context, op *fuseops.LookUpInodeOp) error {
	return nil
}

func (niFs *NotImplementedFileSystem) GetInodeAttributes(ctx context.Context, op *fuseops.GetInodeAttributesOp) error {
	return nil
}

func (niFs *NotImplementedFileSystem) ReadDir(ctx context.Context, op *fuseops.ReadDirOp) error {
	panic("Panic from ReadDir")
	return nil
}

func MakeDirDeviceNotConfigured(p string) error {
	niFs := &NotImplementedFileSystem{&fuseutil.NotImplementedFileSystem{}}
	config := &fuse.MountConfig{}
	server := fuseutil.NewFileSystemServer(niFs)
	f, err := fuse.Mount(p, server, config)
	if err != nil {
		return err
	}

	go f.Join(context.TODO())

	// Sleep to give to mount time to execute.
	time.Sleep(100 * time.Millisecond)

	// Reading from it will cause the fs to crash, like we want.
	if _, err = ioutil.ReadDir(p); err == nil {
		// ReadDir should error with the panic from niFs.ReadDir, if it doesn't, return
		// an error.
		return errors.New("Expected ReadDir op to fail, but it did not.")
	}

	return nil
}

func TestDeviceNotConfiguredRepair(t *testing.T) {
	Convey("", t, func() {
		tmpDir, err := ioutil.TempDir("", "devicenotconfiguredrepair")
		So(err, ShouldBeNil)
		defer os.RemoveAll(tmpDir)

		mountDir := filepath.Join(tmpDir, "mount")
		So(os.Mkdir(mountDir, 0755), ShouldBeNil)

		fakeKlient := &testutil.FakeKlient{
			ReturnMountInfo: req.MountInfoResponse{
				MountFolder: req.MountFolder{
					LocalPath: mountDir,
				},
			},
		}

		r := &DeviceNotConfiguredRepair{
			Log:    discardLogger,
			Stdout: util.NewFprint(ioutil.Discard),
			Klient: fakeKlient,
		}

		Convey("Given a normal dir", func() {
			Convey("When Status() is called", func() {
				Convey("It should return okay", func() {
					ok, err := r.Status()
					So(err, ShouldBeNil)
					So(ok, ShouldBeTrue)
				})
			})
		})

		Convey("Given a DeviceNotConfigured dir", func() {
			err = MakeDirDeviceNotConfigured(mountDir)
			So(err, ShouldBeNil)
			defer fuseklient.Unmount(mountDir)

			Convey("When Status() is called", func() {
				Convey("It should return not okay", func() {
					ok, err := r.Status()
					So(ok, ShouldBeFalse)
					So(err, ShouldBeNil)
				})
			})

			Convey("When Repair() is called", func() {
				Convey("It should call RemoteRemount", func() {
					// Ignoring the error, because it's going to return the status error anyway.
					r.Repair()
					So(fakeKlient.GetCallCount("RemoteRemount"), ShouldEqual, 1)
				})

				Convey("It should run status again", func() {
					err := r.Repair()
					So(err, ShouldNotBeNil)
					So(err.Error(), ShouldContainSubstring, "not-okay")
				})
			})
		})
	})

}
