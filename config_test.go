package main

import (
	"os"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestConfigFolder(t *testing.T) {
	Convey("It should create folder at home", t, func() {
		folder, err := createFolderAtHome(".test/koding")
		So(err, ShouldBeNil)

		_, err = os.Stat(folder)
		So(err, ShouldBeNil)

		Convey("It should do nothing if folder already exists", func() {
			folder, err := createFolderAtHome(".test/koding")
			So(err, ShouldBeNil)

			_, err = os.Stat(folder)
			So(err, ShouldBeNil)

			defer func() {
				err := os.RemoveAll(folder)
				So(err, ShouldBeNil)
			}()
		})
	})
}
