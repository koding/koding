package main

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestFileSystem(t *testing.T) {
	Convey("Given filesystem", t, func() {
		var fs = FileSystem{Transport: &fakeTransport{}}

		Convey("It should return root", func() {
			_, err := fs.Root()
			So(err, ShouldBeNil)
		})
	})
}
