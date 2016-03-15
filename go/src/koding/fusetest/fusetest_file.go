package fusetest

import (
	"io/ioutil"
	"os"
	"path"

	. "github.com/smartystreets/goconvey/convey"
)

func (f *Fusetest) TestCreateFile() {
	f.setupConvey("CreateFile", func(dirPath string) {
		Convey("It should create a new file in root directory", func() {
			filePath := path.Join(dirPath, "newfile")
			err := ioutil.WriteFile(filePath, []byte("Hello World!"), 0500)
			So(err, ShouldBeNil)

			_, err = statFileCheck(filePath, 0500)
			So(err, ShouldBeNil)

			exists, err := f.Remote.FileExists(filePath)
			So(err, ShouldBeNil)
			So(exists, ShouldBeTrue)
		})

		Convey("It should create a new file inside newly created deeply nested directory", func() {
			dirPath1 := path.Join(dirPath, "dir1")
			So(os.MkdirAll(dirPath1, 0700), ShouldBeNil)

			filePath := path.Join(dirPath1, "file")
			err := ioutil.WriteFile(filePath, []byte("Hello World!"), 0700)
			So(err, ShouldBeNil)

			exists, err := f.Remote.FileExists(filePath)
			So(err, ShouldBeNil)
			So(exists, ShouldBeTrue)

			Convey("It should return file properties", func() {
				fi, err := os.OpenFile(filePath, os.O_WRONLY, 0500)
				So(err, ShouldBeNil)

				st, err := fi.Stat()
				So(err, ShouldBeNil)

				So(st.Size(), ShouldEqual, 12)

				size, err := f.Remote.Size(filePath)
				So(err, ShouldBeNil)
				So(size, ShouldEqual, 12)
			})
		})
	})
}

func (f *Fusetest) TestReadFile() {
	f.setupConvey("ReadFile", func(dirPath string) {
		filePath := path.Join(dirPath, "nonexistent")
		err := ioutil.WriteFile(filePath, []byte("Hello World!"), 0700)
		So(err, ShouldBeNil)

		Convey("It should read an existing file in root directory", func() {
			So(readFile(filePath, "Hello World!"), ShouldBeNil)

			contents, err := f.Remote.ReadFile(filePath)
			So(err, ShouldBeNil)
			So(contents, ShouldEqual, "Hello World!")
		})

		Convey("It should read a new file inside newly created deeply nested directory", func() {
			nestedDirPath := path.Join(dirPath, "nested")
			So(os.Mkdir(nestedDirPath, 0700), ShouldBeNil)

			filePath := path.Join(nestedDirPath, "file1")
			err := ioutil.WriteFile(filePath, []byte("Hello World!"), 0500)
			So(err, ShouldBeNil)

			So(readFile(filePath, "Hello World!"), ShouldBeNil)

			contents, err := f.Remote.ReadFile(filePath)
			So(err, ShouldBeNil)
			So(contents, ShouldEqual, "Hello World!")
		})
	})
}

func (f *Fusetest) TestWriteFile() {
	f.setupConvey("WriteFile", func(dirPath string) {
		filePath := path.Join(dirPath, "file")
		err := ioutil.WriteFile(filePath, []byte("Hello World!"), 0700)
		So(err, ShouldBeNil)

		stat, err := os.Stat(filePath)
		So(err, ShouldBeNil)

		Convey("It should write content to existing file in root directory", func() {
			fi, err := os.OpenFile(filePath, os.O_WRONLY, 0755)
			So(err, ShouldBeNil)

			newContent := []byte("This file has been modified!")
			bytes, err := fi.Write(newContent)
			So(err, ShouldBeNil)
			So(bytes, ShouldEqual, len(newContent))

			So(fi.Close(), ShouldBeNil)

			contents, err := f.Remote.ReadFile(filePath)
			So(err, ShouldBeNil)
			So(contents, ShouldEqual, string(newContent))
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

			So(readFile(filePath, string(newContent)), ShouldBeNil)

			contents, err := f.Remote.ReadFile(filePath)
			So(err, ShouldBeNil)
			So(contents, ShouldEqual, string(newContent))
		})

		Convey("It should truncate file to 0 bytes", func() {
			So(os.Truncate(filePath, 0), ShouldBeNil)

			size, err := f.Remote.Size(filePath)
			So(err, ShouldBeNil)
			So(size, ShouldEqual, 0)
		})

		Convey("It should truncate file to less than size of file", func() {
			So(os.Truncate(filePath, stat.Size()-1), ShouldBeNil)

			size, err := f.Remote.Size(filePath)
			So(err, ShouldBeNil)
			So(size, ShouldEqual, stat.Size()-1)
		})

		Convey("It should truncate file to more than size of file", func() {
			So(os.Truncate(filePath, stat.Size()+1), ShouldBeNil)

			size, err := f.Remote.Size(filePath)
			So(err, ShouldBeNil)
			So(size, ShouldEqual, stat.Size()+1)
		})
	})
}
