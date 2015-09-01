package main

import (
	"testing"

	"bazil.org/fuse"

	. "github.com/smartystreets/goconvey/convey"
)

func TestDir(t *testing.T) {
	Convey("Given dir", t, func() {
		Convey("It should lookup file or dir", func() {
			tr := &fakeTransport{
				TripMethodName: "fs.getInfo",
				TripResponse:   fsGetInfoRes{},
			}

			dr := Dir{Node: &Node{Transport: tr}}

			_, err := dr.Lookup(nil, "file")
			So(err, ShouldBeNil)
		})

		Convey("It should return metadata for files and dirs", func() {
			tr := &fakeTransport{
				TripMethodName: "fs.readDirectory",
				TripResponse: fsReadDirectoryRes{
					Files: []fsGetInfoRes{
						fsGetInfoRes{Exists: true, IsDir: false, Name: "testfile"},
					},
				},
			}

			dr := Dir{Node: &Node{Transport: tr}}

			dirents, err := dr.ReadDirAll(nil)
			So(err, ShouldBeNil)
			So(len(dirents), ShouldEqual, 1)
			So(dirents[0].Type, ShouldEqual, fuse.DT_File)
			So(dirents[0].Name, ShouldEqual, "testfile")
		})
	})
}
