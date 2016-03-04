package fusetest

import (
	"io/ioutil"
	"os"
	"path"

	. "github.com/smartystreets/goconvey/convey"
)

func (f *Fusetest) TestMkDir() {
	f.setupConvey("MkDir", func(dirPath string) {
		Convey("It should create dir inside mount", func() {
			fi, err := statDirCheck(dirPath)
			So(err, ShouldBeNil)

			So(fi.Name(), ShouldEqual, "MkDir")

			exists, err := f.Remote.DirExists(dirPath)
			So(err, ShouldBeNil)
			So(exists, ShouldBeTrue)

			Convey("It should create nested dir inside new dir", func() {
				// create /MkDir/dir1
				nestedPath := path.Join(dirPath, "dir1")
				So(os.Mkdir(nestedPath, 0700), ShouldBeNil)

				fi, err := statDirCheck(nestedPath)
				So(err, ShouldBeNil)

				So(fi.Name(), ShouldEqual, "dir1")

				exists, err := f.Remote.DirExists(nestedPath)
				So(err, ShouldBeNil)
				So(exists, ShouldBeTrue)
			})

			Convey("It should create with given permissions", func() {
				fi, err := os.Stat(dirPath)
				So(err, ShouldBeNil)

				So(fi.IsDir(), ShouldBeTrue)
				So(fi.Mode(), ShouldEqual, 0705|os.ModeDir)

				// TODO: fix difffering modes
				//samePerms, err := f.Remote.DirPerms(dirPath, 0705|os.ModeDir)
				//So(err, ShouldBeNil)
				//So(samePerms, ShouldBeTrue)
			})
		})
	})
}

func (f *Fusetest) TestReadDir() {
	f.setupConvey("ReadDir", func(dirPath string) {
		dp := path.Join(dirPath, "dir1")
		So(os.MkdirAll(dp, 0700), ShouldBeNil)

		filePath := path.Join(dirPath, "file1")
		_, err := os.Create(filePath)
		So(err, ShouldBeNil)

		Convey("It should return entries of dir", func() {
			localEntries, err := ioutil.ReadDir(dirPath)
			So(err, ShouldBeNil)

			So(len(localEntries), ShouldEqual, 2)

			// lexical ordering should ensure dir1 will always return before file1
			So(localEntries[0].Name(), ShouldEqual, "dir1")
			So(localEntries[1].Name(), ShouldEqual, "file1")

			remoteEntries, err := f.Remote.GetEntries(dirPath)
			So(err, ShouldBeNil)

			So(len(remoteEntries), ShouldEqual, 2)

			So(remoteEntries[0], ShouldEqual, "dir1")
			So(remoteEntries[1], ShouldEqual, "file1")
		})
	})
}

func (f *Fusetest) TestRename() {
	f.setupConvey("Rename", func(dirPath string) {
		Convey("It should rename dir", func() {
			oldPath := path.Join(dirPath, "oldpath")
			newPath := path.Join(dirPath, "newpath")

			So(os.Mkdir(oldPath, 0700), ShouldBeNil)

			So(os.Rename(oldPath, newPath), ShouldBeNil)

			_, err := os.Stat(oldPath)
			So(err, ShouldNotBeNil)
			So(err.Error(), ShouldContainSubstring, "no such file or directory")

			statDirCheck(newPath)
		})

		Convey("It should rename file", func() {
			oldPath := path.Join(dirPath, "file")
			newPath := path.Join(dirPath, "renamedfile")

			err := ioutil.WriteFile(oldPath, []byte("Hello World!"), 0700)
			So(err, ShouldBeNil)

			fi, err := statFileCheck(oldPath, 0700)
			So(err, ShouldBeNil)

			So(os.Rename(oldPath, newPath), ShouldBeNil)

			_, err = os.Stat(oldPath)
			So(err, ShouldNotBeNil)
			So(err.Error(), ShouldContainSubstring, "no such file or directory")

			fi, err = statFileCheck(newPath, 0700)
			So(err, ShouldBeNil)

			Convey("It should set new file size to be same as old file", func() {
				So(fi.Size(), ShouldEqual, 12) // size of content
			})

			Convey("It should new file content to be same as old file", func() {
				bytes, err := ioutil.ReadFile(newPath)
				So(err, ShouldBeNil)
				So(string(bytes), ShouldEqual, "Hello World!")
			})
		})

		Convey("It should rename file to existing file", func() {
			file1 := path.Join(dirPath, "file1")
			err := ioutil.WriteFile(file1, []byte("Hello"), 0700)
			So(err, ShouldBeNil)

			file2 := path.Join(dirPath, "file2")
			err = ioutil.WriteFile(file2, []byte("World!"), 0700)
			So(err, ShouldBeNil)

			err = os.Rename(file2, file1)
			So(err, ShouldBeNil)

			_, err = os.Stat(file2)
			So(err, ShouldNotBeNil)
			So(err.Error(), ShouldContainSubstring, "no such file or directory")

			_, err = statFileCheck(file1, 0700)
			So(err, ShouldBeNil)

			So(readFile(file1, "World!"), ShouldBeNil)
		})
	})
}

func (f *Fusetest) TestRmDir() {
	f.setupConvey("RmDir", func(dirPath string) {
		nestedDir := path.Join(dirPath, "dir1")
		So(os.MkdirAll(nestedDir, 0705), ShouldBeNil)

		Convey("It should remove directory in root dir", func() {
			So(os.RemoveAll(nestedDir), ShouldBeNil)

			exists, err := f.Remote.DirExists(nestedDir)
			So(err, ShouldBeNil)
			So(exists, ShouldBeFalse)
		})

		Convey("It should remove all entries inside specified directory", func() {
			dirPath2 := path.Join(nestedDir, "dir2")

			So(os.MkdirAll(dirPath2, 0700), ShouldBeNil)

			filePath := path.Join(nestedDir, "file")
			err := ioutil.WriteFile(filePath, []byte("Hello World!"), 0500)
			So(err, ShouldBeNil)

			err = os.RemoveAll(nestedDir)
			So(err, ShouldBeNil)

			_, err = os.Stat(dirPath2)
			So(err, ShouldNotBeNil)
			So(err.Error(), ShouldContainSubstring, "no such file or directory")

			exists, err := f.Remote.DirExists(dirPath2)
			So(err, ShouldBeNil)
			So(exists, ShouldBeFalse)

			_, err = os.Stat(nestedDir)
			So(err, ShouldNotBeNil)
			So(err.Error(), ShouldContainSubstring, "no such file or directory")

			_, err = os.Stat(filePath)
			So(err, ShouldNotBeNil)
			So(err.Error(), ShouldContainSubstring, "no such file or directory")

			exists, err = f.Remote.DirExists(filePath)
			So(err, ShouldBeNil)
			So(exists, ShouldBeFalse)
		})
	})
}
