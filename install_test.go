package main

import (
	"io/ioutil"
	"os"
	"path/filepath"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestCreateLogFile(t *testing.T) {
	testDir := "_test"
	tmpDir := filepath.Join(testDir, "tmp")
	testFile := filepath.Join(tmpDir, "logfile")

	if err := os.MkdirAll(tmpDir, 0755); err != nil {
		t.Fatal(err)
	}

	Convey("Given a path that already exists", t, func() {
		So(os.RemoveAll(testFile), ShouldBeNil)
		// Chmod it to something other than -rw-rw-rw-
		So(ioutil.WriteFile(testFile, []byte("foo"), 0777), ShouldBeNil)

		Convey("Then chmod the file to -rw-rw-rw-", func() {
			f, err := createLogFile(testFile)
			So(err, ShouldBeNil)
			defer f.Close()

			fi, err := f.Stat()
			So(err, ShouldBeNil)
			So(fi.Mode().String(), ShouldEqual, "-rw-rw-rw-")
		})

		Convey("Then do not replace the file", func() {
			f, err := createLogFile(testFile)
			So(err, ShouldBeNil)
			f.Close()

			b, err := ioutil.ReadFile(testFile)
			So(err, ShouldBeNil)
			So(string(b), ShouldEqual, "foo")
		})
	})

	Convey("Given a path that does not exist", t, func() {
		So(os.RemoveAll(testFile), ShouldBeNil)

		Convey("Then create the file", func() {
			f, err := createLogFile(testFile)
			So(err, ShouldBeNil)
			f.Close()

			// If it doesn't exist, stat will fail with IsNotExist
			_, err = os.Stat(testFile)
			So(err, ShouldBeNil)
		})

		Convey("Then chmod the file to -rw-rw-rw-", func() {
			f, err := createLogFile(testFile)
			So(err, ShouldBeNil)
			defer f.Close()

			fi, err := f.Stat()
			So(err, ShouldBeNil)
			So(fi.Mode().String(), ShouldEqual, "-rw-rw-rw-")
		})
	})

	os.RemoveAll(testDir)
}
