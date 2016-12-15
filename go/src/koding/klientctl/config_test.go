package main

import (
	"os"
	"path/filepath"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestConfigFolder(t *testing.T) {
	// cleanup any artificats from old runs
	os.RemoveAll(filepath.Join(ConfigFolder, "_test"))

	Convey("It should create folder at home", t, func() {
		folder, err := createFolderAtHome("_test/koding")
		So(err, ShouldBeNil)

		_, err = os.Stat(folder)
		So(err, ShouldBeNil)

		Convey("It should do nothing if folder already exists", func() {
			folder, err := createFolderAtHome("_test/koding")
			So(err, ShouldBeNil)

			_, err = os.Stat(folder)
			So(err, ShouldBeNil)

			defer func() {
				err := os.RemoveAll(filepath.Join(ConfigFolder, "_test"))
				So(err, ShouldBeNil)
			}()
		})
	})
}
