package fusetest

import (
	"io/ioutil"
	"os"
	"path"
	"testing"
	"time"

	. "github.com/smartystreets/goconvey/convey"
)

func testCreateFile(t *testing.T, mountDir string) {
	Convey("CreateFile", t, createDir(mountDir, "CreateFile", func(dirPath string) {
		Convey("It should create a new file in root directory", func() {
			filePath := path.Join(dirPath, "newfile")
			err := ioutil.WriteFile(filePath, []byte("Hello World!"), 0500)
			So(err, ShouldBeNil)

			_, err = statFileCheck(filePath, 0500)
			So(err, ShouldBeNil)
		})

		Convey("It should create a new file inside newly created deeply nested directory", func() {
			dirPath1 := path.Join(dirPath, "dir1")
			So(os.MkdirAll(dirPath1, 0700), ShouldBeNil)

			filePath := path.Join(dirPath1, "file")
			err := ioutil.WriteFile(filePath, []byte("Hello World!"), 0700)
			So(err, ShouldBeNil)

			Convey("It should return file properties", func() {
				fi, err := os.OpenFile(filePath, os.O_WRONLY, 0500)
				So(err, ShouldBeNil)

				st, err := fi.Stat()
				So(err, ShouldBeNil)

				So(st.IsDir(), ShouldEqual, false)
				So(st.Name(), ShouldEqual, "file")
				So(st.Size(), ShouldEqual, 12)
			})
		})
	}))
}

func testOpenFile(t *testing.T, mountDir string) {
	Convey("OpenFile", t, createDir(mountDir, "OpenFile", func(dirPath string) {
		Convey("It should return err when trying to open nonexistent file", func() {
			filePath := path.Join(mountDir, "nonexistent")
			_, err := os.OpenFile(filePath, os.O_WRONLY, 0400)
			So(err, ShouldNotBeNil)
		})

		Convey("It should open file in root directory", func() {
			filePath := path.Join(dirPath, "file")

			err := ioutil.WriteFile(filePath, []byte("Hello World!"), 0700)
			So(err, ShouldBeNil)

			fi, err := os.OpenFile(filePath, os.O_WRONLY, 0400)
			So(err, ShouldBeNil)

			Convey("It should return file properties", func() {
				st, err := fi.Stat()
				So(err, ShouldBeNil)

				// Get the time difference between when the file was created, and
				// when this specific test was run.
				fileCreatedAgo := time.Now().UTC().Sub(st.ModTime().UTC())

				So(st.IsDir(), ShouldEqual, false)
				So(st.Name(), ShouldEqual, "file")
				So(st.Size(), ShouldEqual, 12)

				// Check if the diff was small. Within 1 seconds, to account for
				// any laggy/blocking tests..
				So(fileCreatedAgo, ShouldAlmostEqual, 0, 1*time.Second)
			})
		})
	}))
}

func testReadFile(t *testing.T, mountDir string) {
	Convey("ReadFile", t, createDir(mountDir, "OpenFile", func(dirPath string) {
		filePath := path.Join(dirPath, "nonexistent")
		err := ioutil.WriteFile(filePath, []byte("Hello World!"), 0700)
		So(err, ShouldBeNil)

		Convey("It should read an existing file in root directory", func() {
			So(readFile(filePath, "Hello World!"), ShouldBeNil)

			fi, err := os.OpenFile(filePath, os.O_RDONLY, 0755)
			So(err, ShouldBeNil)

			dst := make([]byte, 12) // size of string
			n, err := fi.Read(dst)
			So(err, ShouldBeNil)
			So(string(dst), ShouldEqual, "Hello World!")
			So(n, ShouldEqual, 12) // size of string

			Convey("It should read file with specified offset: 0", func() {
				So(readFileAt(fi, 0, "Hello World!"), ShouldBeNil)
			})

			Convey("It should read with specified offset: 4", func() {
				So(readFileAt(fi, 6, "World!"), ShouldBeNil)
			})
		})

		Convey("It should read a new file inside newly created deeply nested directory", func() {
			nestedDirPath := path.Join(dirPath, "nested")
			So(os.Mkdir(nestedDirPath, 0700), ShouldBeNil)

			filePath := path.Join(nestedDirPath, "file1")
			err := ioutil.WriteFile(filePath, []byte("Hello World!"), 0500)
			So(err, ShouldBeNil)

			So(readFile(filePath, "Hello World!"), ShouldBeNil)

			fi, err := os.OpenFile(filePath, os.O_RDONLY, 0755)
			So(err, ShouldBeNil)

			Convey("It should read file with specified offset: 0", func() {
				So(readFileAt(fi, 0, "Hello World!"), ShouldBeNil)
			})

			Convey("It should read with specified offset: 4", func() {
				So(readFileAt(fi, 6, "World!"), ShouldBeNil)
			})
		})
	}))
}

func testWriteFile(t *testing.T, mountDir string) {
	Convey("WriteFile", t, createDir(mountDir, "WriteFile", func(dirPath string) {
		filePath := path.Join(dirPath, "file")
		err := ioutil.WriteFile(filePath, []byte("Hello World!"), 0700)
		So(err, ShouldBeNil)

		Reset(func() { So(os.RemoveAll(dirPath), ShouldBeNil) })

		stat, err := os.Stat(filePath)
		So(err, ShouldBeNil)

		Convey("It should return error when trying to modify file with wrong flag", func() {
			fi, err := os.OpenFile(filePath, os.O_RDONLY, 0755)
			So(err, ShouldBeNil)

			_, err = fi.Write([]byte{})
			So(err, ShouldNotBeNil)
			So(err.Error(), ShouldContainSubstring, "bad file descriptor")
		})

		Convey("It should write content to existing file in root directory", func() {
			fi, err := os.OpenFile(filePath, os.O_WRONLY, 0755)
			So(err, ShouldBeNil)

			newContent := []byte("This file has been modified!")
			bytes, err := fi.Write(newContent)
			So(err, ShouldBeNil)
			So(bytes, ShouldEqual, len(newContent))

			So(fi.Close(), ShouldBeNil)
		})

		Convey("It should modify a new file inside newly created deeply nested directory", func() {
			dirPath := path.Join(dirPath, "dir1")
			So(os.Mkdir(dirPath, 0705), ShouldBeNil)

			filePath := path.Join(dirPath, "file1")
			err := ioutil.WriteFile(filePath, []byte("Hello World!"), 0700)
			So(err, ShouldBeNil)

			fi, err := os.OpenFile(filePath, os.O_WRONLY, 0500)
			So(err, ShouldBeNil)

			newContent := []byte("This file has been modified!")
			bytes, err := fi.Write(newContent)
			So(err, ShouldBeNil)
			So(bytes, ShouldEqual, len(newContent))

			So(fi.Close(), ShouldBeNil)

			So(readFile(filePath, string(newContent)), ShouldBeNil)
		})

		Convey("It should truncate file to 0 bytes", func() {
			So(os.Truncate(filePath, 0), ShouldBeNil)

			newStat, err := os.Stat(filePath)
			So(err, ShouldBeNil)
			So(newStat.Size(), ShouldEqual, 0)
		})

		Convey("It should truncate file to less than size of file", func() {
			So(os.Truncate(filePath, stat.Size()-1), ShouldBeNil)

			newStat, err := os.Stat(filePath)
			So(err, ShouldBeNil)
			So(newStat.Size(), ShouldEqual, stat.Size()-1)
		})

		Convey("It should truncate file to more than size of file", func() {
			So(os.Truncate(filePath, stat.Size()+1), ShouldBeNil)

			newStat, err := os.Stat(filePath)
			So(err, ShouldBeNil)
			So(newStat.Size(), ShouldEqual, stat.Size()+1)
		})
	}))
}
