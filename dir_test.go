package main

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestDir(t *testing.T) {
	Convey("Given dir", t, func() {
		var d = Dir{Node: &Node{Transport: &fakeTransport{}}}

		Convey("It should lookup file or dir", func() {
			_, err := d.Lookup(nil, "file")
			So(err, ShouldBeNil)
		})

		Convey("It should return metadata for files and dirs", func() {
			_, err := d.ReadDirAll(nil)
			So(err, ShouldBeNil)
		})
	})
}
