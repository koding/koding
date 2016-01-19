package transport

import (
	"io/ioutil"
	"os"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestDiskTransport(t *testing.T) {
	var _ Transport = (*DiskTransport)(nil)
}

func TestDTCreateDir(t *testing.T) {
	Convey("CreateDir", t, func() {
		dt := newDiskTransport()

		Convey("It should create dir with mode", func() {
			err := dt.CreateDir("1", 0700)
			So(err, ShouldBeNil)
			statDirCheck(dt.fullPath("1"))
		})

		Convey("It should create nested dir with mode", func() {
			err := dt.CreateDir("2/a", 0700)
			So(err, ShouldBeNil)
			statDirCheck(dt.fullPath("2"))
			statDirCheck(dt.fullPath("2/a"))
		})

		Convey("It should create dir inside existing dir", func() {
			err := dt.CreateDir("1", 0700)
			So(err, ShouldBeNil)
			statDirCheck(dt.fullPath("1"))

			err = dt.CreateDir("1/a", 0700)
			So(err, ShouldBeNil)
			statDirCheck(dt.fullPath("1/a"))
		})
	})
}

func TestDTReadDir(t *testing.T) {
	Convey("DiskTransport#ReadDir", t, func() {
		dt := newDiskTransport()

		// create dir with a dir inside
		err := dt.CreateDir("1/a", 0700)
		So(err, ShouldBeNil)

		// create file inside dir
		err = dt.WriteFile("1/b", []byte{})
		So(err, ShouldBeNil)

		resp, err := dt.ReadDir("1", []string{})
		So(err, ShouldBeNil)

		entries := resp.Files

		Convey("It should create return entries of dir", func() {
			So(len(entries), ShouldEqual, 2)
		})

		Convey("It should create return dir with info", func() {
			So(entries[0].IsDir, ShouldEqual, true)
			So(entries[0].Name, ShouldEqual, "a")
		})

		Convey("It should create return file with info", func() {
			So(entries[1].IsDir, ShouldEqual, false)
			So(entries[1].Name, ShouldEqual, "b")
		})
	})
}

func TestDTRename(t *testing.T) {
	Convey("Rename", t, func() {
		dt := newDiskTransport()

		err := dt.WriteFile("file", []byte("hello world!"))
		So(err, ShouldBeNil)
		statFileCheck(dt.fullPath("file"), 0644)

		err = dt.Rename("file", "file1")
		So(err, ShouldBeNil)

		Convey("It should change name of entry from old to new", func() {
			resp, err := dt.ReadFile("file1")
			So(err, ShouldBeNil)
			So(string(resp.Content), ShouldEqual, "hello world!")
		})

		Convey("It should remove old entry", func() {
			_, err = os.Stat(dt.fullPath("file"))
			So(err.Error(), ShouldContainSubstring, "no such file or directory")
		})
	})
}

func TestDTRemove(t *testing.T) {
	Convey("Remove", t, func() {
		dt := newDiskTransport()

		err := dt.WriteFile("file", []byte("hello world!"))
		So(err, ShouldBeNil)

		err = dt.Remove("file")
		So(err, ShouldBeNil)

		Convey("It should remove old entry", func() {
			_, err = os.Stat(dt.fullPath("file"))
			So(err.Error(), ShouldContainSubstring, "no such file or directory")
		})
	})
}

func TestDTReadFile(t *testing.T) {
	Convey("DiskTransport#ReadFile", t, func() {
		dt := newDiskTransport()

		Convey("It should read contents of file", func() {
			err := dt.WriteFile("file", []byte("hello world!"))
			So(err, ShouldBeNil)

			resp, err := dt.ReadFile("file")
			So(err, ShouldBeNil)
			So(string(resp.Content), ShouldEqual, "hello world!")
		})
	})
}

func TestDTWriteFile(t *testing.T) {
	Convey("DiskTransport#WriteFile", t, func() {
		dt := newDiskTransport()

		Convey("It should write file with contents", func() {
			err := dt.WriteFile("1", []byte{1})
			So(err, ShouldBeNil)
			statFileCheck(dt.fullPath("1"), 0644)
		})
	})
}

///// Helpers

func newDiskTransport() *DiskTransport {
	mountDir, err := ioutil.TempDir("", "mounttest")
	if err != nil {
		panic(err)
	}

	//fmt.Printf("Created temp dir at %s\n", mountDir)

	return &DiskTransport{
		Path: mountDir,
	}
}

func statFileCheck(filePath string, mode os.FileMode) {
	fi, err := os.Stat(filePath)
	So(err, ShouldBeNil)

	So(fi.IsDir(), ShouldBeFalse)
	So(fi.Mode(), ShouldEqual, mode)
}

func statDirCheck(dir string) {
	fi, err := os.Stat(dir)
	So(err, ShouldBeNil)

	So(fi.IsDir(), ShouldBeTrue)
	So(fi.Mode(), ShouldEqual, 0700|os.ModeDir)
}
