package fs

import (
	"io/ioutil"
	"os"
	"path"
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
			t := &fakeTransport{
				TripResponses: map[string]interface{}{
					"fs.readDirectory": transport.FsReadDirectoryRes{Files: []transport.FsGetInfoRes{}},
				},
			}
			k := newknfs(t)

			_, err := k.Mount()
			So(err, ShouldBeNil)

			So(_unmount(k), ShouldBeNil)
		})
	})
}

func TestFolder(tt *testing.T) {
	Convey("Given mounted folder", tt, func() {
		t := &fakeTransport{
			TripResponses: map[string]interface{}{
				"fs.readDirectory":   transport.FsReadDirectoryRes{Files: []transport.FsGetInfoRes{}},
				"fs.createDirectory": true,
			},
		}

		k := newknfs(t)

		_, err := k.Mount()
		So(err, ShouldBeNil)

		Convey("It should return contents when empty", func() {
			fi, err := os.Stat(k.MountPath)
			So(err, ShouldBeNil)

			So(fi.IsDir(), ShouldBeTrue)
			So(fi.Mode(), ShouldEqual, 0700|os.ModeDir)
		})

		Convey("It should create folder inside mounted directory", func() {
			newFolder := path.Join(k.MountPath, "folder")

			err := os.Mkdir(newFolder, 0700)
			So(err, ShouldBeNil)

			stat := func(folderPath string) {
				fi, err := os.Stat(folderPath)
				So(err, ShouldBeNil)

				So(fi.IsDir(), ShouldBeTrue)
				So(fi.Mode(), ShouldEqual, 0700|os.ModeDir)
			}

			stat(newFolder)

			Convey("It should create folder inside newly created folder recursively", func() {
				err := os.MkdirAll(path.Join(newFolder, "1", "2"), 0700)
				So(err, ShouldBeNil)

				stat(path.Join(newFolder, "1"))
				stat(path.Join(newFolder, "1", "2"))
			})

			Convey("It should create with given permissions", func() {
				folderPath := path.Join(newFolder, "p")

				err := os.MkdirAll(folderPath, 0705)
				So(err, ShouldBeNil)

				fi, err := os.Stat(folderPath)
				So(err, ShouldBeNil)

				So(fi.IsDir(), ShouldBeTrue)
				So(fi.Mode(), ShouldEqual, 0705|os.ModeDir)
			})

			Convey("It should return err when creating already existing folder", func() {
			})
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
