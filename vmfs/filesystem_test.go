package vmfs

import (
	"testing"

	"github.com/koding/fuseklient/transport"
	. "github.com/smartystreets/goconvey/convey"
)

var (
	// TODO: remove hardcoded fullpath
	remotePath = "/fusemount"
	localPath  = "/Users/senthil/work/fuse/fuseklient/mount"
)

func TestFileSystem(t *testing.T) {
	Convey("Given filesystem", t, func() {
		Convey("It should return error if remote foler doesn't exist", func() {
			ft := &fakeTransport{
				TripMethodName: "fs.getInfo",
				TripResponse:   transport.FsGetInfoRes{Exists: false},
			}

			fl := FileSystem{
				Transport:  ft,
				MountName:  "test",
				LocalPath:  localPath,
				RemotePath: remotePath,
			}

			_, err := fl.Root()
			So(err, ShouldNotBeNil)
		})

		Convey("It should return root", func() {
			ft := &fakeTransport{
				TripMethodName: "fs.getInfo",
				TripResponse:   transport.FsGetInfoRes{Exists: true},
			}

			fl := FileSystem{
				Transport:  ft,
				MountName:  "test",
				LocalPath:  localPath,
				RemotePath: remotePath,
			}

			_, err := fl.Root()
			So(err, ShouldBeNil)
		})
	})
}
