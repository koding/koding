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
		f := FileSystem{
			MountName:         "test",
			InternalMountPath: internalPath,
			ExternalMountPath: externalPath,
		}

		Convey("It should return root", func() {
			_, err := f.Root()
			So(err, ShouldBeNil)
		})
	})
}
