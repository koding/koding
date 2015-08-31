package main

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestFile(t *testing.T) {
	Convey("Given file", t, func() {
		var f = File{Node: &Node{Transport: &fakeTransport{}}}

		Convey("It should return contents", func() {
			contents, err := f.ReadAll(nil)
			So(err, ShouldBeNil)
			So(contents, ShouldBeEmpty)
		})
	})
}
