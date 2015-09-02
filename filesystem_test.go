package main

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

var (
	// TODO: remove hardcoded fullpath
	internalPath = "/Users/senthil/work/fuse/prototype/internalPath/fuseproto"
	externalPath = "/fuseproto"
)

func TestFileSystem(t *testing.T) {
	Convey("Given filesystem", t, func() {
		Convey("It should return error if external foler doesn't exist", func() {
			ft := &fakeTransport{
				TripMethodName: "fs.getInfo",
				TripResponse:   fsGetInfoRes{Exists: false},
			}

			fl := FileSystem{
				Transport:         ft,
				MountName:         "test",
				InternalMountPath: internalPath,
				ExternalMountPath: externalPath,
			}

			_, err := fl.Root()
			So(err, ShouldNotBeNil)
		})

		Convey("It should return root", func() {
			ft := &fakeTransport{
				TripMethodName: "fs.getInfo",
				TripResponse:   fsGetInfoRes{Exists: true},
			}

			fl := FileSystem{
				Transport:         ft,
				MountName:         "test",
				InternalMountPath: internalPath,
				ExternalMountPath: externalPath,
			}

			_, err := fl.Root()
			So(err, ShouldBeNil)
		})
	})
}
