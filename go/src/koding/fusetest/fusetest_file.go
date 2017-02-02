package fusetest

import (
	"io/ioutil"
	"os"
	"path/filepath"

	. "github.com/smartystreets/goconvey/convey"
)

func (f *Fusetest) TestCreateFile() {
	f.setupConvey("CreateFile", func(dirName string) {
		Convey("It should create a new file in root directory", func() {
			fileName := filepath.Join(dirName, "file")

			err := ioutil.WriteFile(f.fullMountPath(fileName), []byte("Hello World!"), 0500)
			So(err, ShouldBeNil)

			_, err = statFileCheck(f.fullMountPath(fileName), 0500)
			So(err, ShouldBeNil)

			exists, err := f.Remote.FileExists(fileName)
			So(err, ShouldBeNil)
			So(exists, ShouldBeTrue)
		})

		Convey("It should create a new file inside newly created deeply nested directory", func() {
			nestedDir := filepath.Join(dirName, "nestedDir")
			nestedFile := filepath.Join(nestedDir, "file")

			So(os.MkdirAll(f.fullMountPath(nestedDir), 0700), ShouldBeNil)

			err := ioutil.WriteFile(f.fullMountPath(nestedFile), []byte("Hello World!"), 0700)
			So(err, ShouldBeNil)

			_, err = statFileCheck(f.fullMountPath(nestedFile), 0700)
			So(err, ShouldBeNil)

			exists, err := f.Remote.FileExists(nestedFile)
			So(err, ShouldBeNil)
			So(exists, ShouldBeTrue)

			Convey("It should return file properties", func() {
				fi, err := os.OpenFile(f.fullMountPath(nestedFile), os.O_WRONLY, 0500)
				So(err, ShouldBeNil)

				st, err := fi.Stat()
				So(err, ShouldBeNil)

				So(st.Size(), ShouldEqual, 12)

				size, err := f.Remote.Size(nestedFile)
				So(err, ShouldBeNil)
				So(size, ShouldEqual, 12)
			})
		})
	})
}

func (f *Fusetest) TestReadFile() {
	f.setupConvey("ReadFile", func(dirName string) {
		fileName := filepath.Join(dirName, "file")

		err := ioutil.WriteFile(f.fullMountPath(fileName), []byte("Hello World!"), 0700)
		So(err, ShouldBeNil)

		Convey("It should read an existing file in root directory", func() {
			So(f.CheckLocalFileContents(fileName, "Hello World!"), ShouldBeNil)

			contents, err := f.Remote.ReadFile(fileName)
			So(err, ShouldBeNil)
			So(contents, ShouldEqual, "Hello World!")
		})

		Convey("It should read a new file inside newly created deeply nested directory", func() {
			nestedDir := filepath.Join(dirName, "dir1")
			nestedFile := filepath.Join(nestedDir, "file1")

			So(os.Mkdir(f.fullMountPath(nestedDir), 0700), ShouldBeNil)

			err := ioutil.WriteFile(f.fullMountPath(nestedFile), []byte("Hello World!"), 0500)
			So(err, ShouldBeNil)

			So(f.CheckLocalFileContents(fileName, "Hello World!"), ShouldBeNil)

			contents, err := f.Remote.ReadFile(fileName)
			So(err, ShouldBeNil)
			So(contents, ShouldEqual, "Hello World!")
		})
	})
}

func (f *Fusetest) TestWriteFile() {
	f.setupConvey("WriteFile", func(dirName string) {
		fileName := filepath.Join(dirName, "file")

		err := ioutil.WriteFile(f.fullMountPath(fileName), []byte("Hello World!"), 0700)
		So(err, ShouldBeNil)

		Convey("It should write content to existing file in root directory", func() {
			fi, err := os.OpenFile(f.fullMountPath(fileName), os.O_WRONLY, 0755)
			So(err, ShouldBeNil)

			newContent := []byte("This file has been modified!")
			bytes, err := fi.Write(newContent)
			So(err, ShouldBeNil)
			So(bytes, ShouldEqual, len(newContent))

			So(fi.Close(), ShouldBeNil)

			contents, err := f.Remote.ReadFile(fileName)
			So(err, ShouldBeNil)
			So(contents, ShouldEqual, string(newContent))
		})

		Convey("It should large write content to file in root directory", func() {
			fi, err := os.OpenFile(f.fullMountPath(fileName), os.O_WRONLY, 0755)
			So(err, ShouldBeNil)

			newContent := []byte("This file has been modified!\n")
			for i := 0; i < 1000; i++ {
				bytesRead, err := fi.Write(newContent)
				So(err, ShouldBeNil)
				So(bytesRead, ShouldEqual, len(newContent))
			}

			So(fi.Close(), ShouldBeNil)

			size, err := f.Remote.Size(fileName)
			So(size, ShouldEqual, 1000*len(newContent))
			So(err, ShouldBeNil)

			Convey("It should read file in chunks", func() {
				fi, err := os.OpenFile(f.fullMountPath(fileName), os.O_RDONLY, 0755)
				So(err, ShouldBeNil)

				for i := 0; i < 1000; i++ {
					So(readFileAt(fi, i*len(newContent), string(newContent)), ShouldBeNil)
				}

				So(fi.Close(), ShouldBeNil)
			})
		})

		Convey("It should modify a new file inside newly created deeply nested directory", func() {
			nestedDir := filepath.Join(dirName, "dir1")
			nestedFile := filepath.Join(nestedDir, "file1")

			So(os.Mkdir(f.fullMountPath(nestedDir), 0705), ShouldBeNil)

			err := ioutil.WriteFile(f.fullMountPath(nestedFile), []byte("Hello World!"), 0700)
			So(err, ShouldBeNil)

			fi, err := os.OpenFile(f.fullMountPath(nestedFile), os.O_WRONLY, 0500)
			So(err, ShouldBeNil)

			newContent := []byte("This file has been modified!")
			bytes, err := fi.Write(newContent)
			So(err, ShouldBeNil)
			So(bytes, ShouldEqual, len(newContent))

			So(fi.Close(), ShouldBeNil)

			So(f.CheckLocalFileContents(nestedFile, string(newContent)), ShouldBeNil)

			contents, err := f.Remote.ReadFile(nestedFile)
			So(err, ShouldBeNil)
			So(contents, ShouldEqual, string(newContent))
		})

		Convey("It should truncate file to 0 bytes", func() {
			So(os.Truncate(f.fullMountPath(fileName), 0), ShouldBeNil)

			size, err := f.Remote.Size(fileName)
			So(err, ShouldBeNil)
			So(size, ShouldEqual, 0)
		})

		stat, err := os.Stat(f.fullMountPath(fileName))
		So(err, ShouldBeNil)

		Convey("It should truncate file to less than size of file", func() {
			So(os.Truncate(f.fullMountPath(fileName), stat.Size()-1), ShouldBeNil)

			size, err := f.Remote.Size(fileName)
			So(err, ShouldBeNil)
			So(size, ShouldEqual, stat.Size()-1)
		})

		Convey("It should truncate file to more than size of file", func() {
			So(os.Truncate(f.fullMountPath(fileName), stat.Size()+1), ShouldBeNil)

			size, err := f.Remote.Size(fileName)
			So(err, ShouldBeNil)
			So(size, ShouldEqual, stat.Size()+1)
		})
	})
}
