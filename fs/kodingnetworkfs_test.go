package fs

import (
	"io/ioutil"
	"os"
	"path/filepath"
	"testing"

	"github.com/jacobsa/fuse/fuseutil"
	"github.com/koding/fuseklient/config"
	"github.com/koding/fuseklient/transport"
	. "github.com/smartystreets/goconvey/convey"
)

func TestKodingNetworkFS(tt *testing.T) {
	Convey("", tt, func() {
		Convey("It should implement all fuse.FileSystem methods", func() {
			var _ fuseutil.FileSystem = (*KodingNetworkFS)(nil)
		})

		Convey("It should mount and unmount a folder", func() {
			k := newknfs(&fakeTransport{})

			_, err := k.Mount()
			So(err, ShouldBeNil)

			So(_unmount(k), ShouldBeNil)
		})
	})
}

func TestFolder(tt *testing.T) {
	Convey("Given mounted folder", tt, func() {
		t := &fakeTransport{}
		k := newknfs(t)

		_, err := k.Mount()
		So(err, ShouldBeNil)

		Convey("It should return contents when empty", func() {
			fi, err := os.Stat(k.MountPath)
			So(err, ShouldBeNil)

			So(fi.IsDir(), ShouldBeTrue)
			So(fi.Mode(), ShouldEqual, 0700|os.ModeDir)
		})

		defer _unmount(k)
	})
}

func newknfs(t transport.Transport) *KodingNetworkFS {
	mountFolder, err := ioutil.TempDir("", "mounttest")
	if err != nil {
		panic(err)
	}

	c := &config.FuseConfig{LocalPath: mountFolder}
	return NewKodingNetworkFS(t, c)
}

func _unmount(k *KodingNetworkFS) error {
	// ioutil.TempDir creates folders with `/private` prefix, however it
	// doesn't include it in the return path; without this unmout fails.
	oldPath := k.MountPath
	k.MountPath = filepath.Join("/private", k.MountPath)
	if err := k.Unmount(); err != nil {
		return err
	}

	return os.RemoveAll(oldPath)
}
