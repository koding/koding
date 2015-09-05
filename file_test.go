package main

import (
	"testing"

	"github.com/koding/fuseklient/transport"
	. "github.com/smartystreets/goconvey/convey"
)

func TestFile(t *testing.T) {
	Convey("Given file", t, func() {
		ft := &fakeTransport{
			TripMethodName: "fs.readFile",
			TripResponse:   transport.FsReadFileRes{},
		}

		fl := File{Node: &Node{Transport: ft}}

		Convey("It should return contents", func() {
			contents, err := fl.ReadAll(nil)
			So(err, ShouldBeNil)
			So(contents, ShouldBeEmpty)
		})
	})
}
