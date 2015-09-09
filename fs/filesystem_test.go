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

func TestFileSystem(tt *testing.T) {
	Convey("", tt, func() {
		Convey("It should implement all fuse.FileSystem methods", func() {
			var _ fuseutil.FileSystem = (*FileSystem)(nil)
		})

		Convey("It should mount and unmount a folder", func() {
			f := newfs(&fakeTransport{})

			So(f.Mount(), ShouldBeNil)
			So(_unmount(f), ShouldBeNil)
		})
	})
}

func newfs(t transport.Transport) *FileSystem {
	mountFolder, err := ioutil.TempDir("", "mounttest")
	if err != nil {
		panic(err)
	}

	c := &config.FuseConfig{LocalPath: mountFolder, RemotePath: "/"}

	return NewFileSystem(t, c)
}

func _unmount(f *FileSystem) error {
	// ioutil.TempDir creates folders with `/private` prefix, however it
	// doesn't include it in the return path; without this unmout fails
	f.LocalPath = filepath.Join("/private", f.LocalPath)
	if err := f.Unmount(); err != nil {
		return err
	}

	return os.RemoveAll(f.LocalPath)
}
