package fusetest

import (
	"io/ioutil"
	"os"
	"path/filepath"

	. "github.com/smartystreets/goconvey/convey"
)

func (f *Fusetest) TestMkDir() {
	f.setupConvey("MkDir", func(dirName string) {
		Convey("It should create dir inside mount", func() {
			// check if file was created on local/cache
			So(f.CheckLocalEntry(dirName), ShouldBeNil)

			// check if file was created remote
			exists, err := f.Remote.DirExists(dirName)
			So(err, ShouldBeNil)
			So(exists, ShouldBeTrue)

			Convey("It should create nested dir inside new dir", func() {
				nestedPath := filepath.Join(f.fullMountPath(dirName), "dir1")
				nestedName := filepath.Join(dirName, "dir1")

				// create /MkDir/dir1
				So(os.Mkdir(nestedPath, 0700), ShouldBeNil)

				// check if file was created on local/cache
				So(f.CheckLocalEntry(nestedName), ShouldBeNil)

				// check if file was created remote
				exists, err := f.Remote.DirExists(nestedName)
				So(err, ShouldBeNil)
				So(exists, ShouldBeTrue)
			})

			Convey("It should create with given permissions", func() {
				So(f.CheckLocalEntryIsDir(dirName, 0705|os.ModeDir), ShouldBeNil)

				// TODO: fix difffering modes on remote and local
				//samePerms, err := f.Remote.DirPerms(dirPath, 0705|os.ModeDir)
				//So(err, ShouldBeNil)
				//So(samePerms, ShouldBeTrue)
			})
		})
	})
}

func (f *Fusetest) TestReadDir() {
	f.setupConvey("ReadDir", func(dirName string) {
		// create dir inside dir
		nestedDirName := filepath.Join(dirName, "dir1")
		So(os.MkdirAll(f.fullMountPath(nestedDirName), 0700), ShouldBeNil)

		// create file inside dir
		nestedFilePath := filepath.Join(dirName, "file1")
		_, err := os.Create(f.fullMountPath(nestedFilePath))
		So(err, ShouldBeNil)

		Convey("It should return entries of dir", func() {
			// check local/cache for above created dir & file are there
			So(f.CheckDirContents(dirName, []string{"dir1", "file1"}), ShouldBeNil)

			// check remote for above created dir & file are there
			remoteEntries, err := f.Remote.GetEntries(dirName)
			So(err, ShouldBeNil)

			So(len(remoteEntries), ShouldEqual, 2)

			So(remoteEntries[0], ShouldEqual, "dir1")
			So(remoteEntries[1], ShouldEqual, "file1")
		})
	})
}

func (f *Fusetest) TestRmDir() {
	f.setupConvey("RmDir", func(dir string) {
		nestedDir := filepath.Join(dir, "dir1")

		So(os.MkdirAll(f.fullMountPath(nestedDir), 0705), ShouldBeNil)

		Convey("It should remove directory in root dir", func() {
			So(os.RemoveAll(f.fullMountPath(nestedDir)), ShouldBeNil)

			exists, err := f.Remote.DirExists(nestedDir)
			So(err, ShouldBeNil)
			So(exists, ShouldBeFalse)
		})

		Convey("It should remove all entries inside specified directory", func() {
			deepNestedDir := filepath.Join(nestedDir, "dir2")
			nestedFile := filepath.Join(nestedDir, "file")

			// create RmDir/dir1/dir2
			So(os.MkdirAll(f.fullMountPath(deepNestedDir), 0700), ShouldBeNil)

			// create RmDir/dir1/file
			err := ioutil.WriteFile(f.fullMountPath(nestedFile), []byte("Hello World!"), 0500)
			So(err, ShouldBeNil)

			// delete RmDir/dir1/dir2
			err = os.RemoveAll(f.fullMountPath(nestedDir))
			So(err, ShouldBeNil)

			// check loca/cache RmDir/dir1/dir2
			So(f.CheckLocalEntryNotExists(deepNestedDir), ShouldBeNil)

			// check remote RmDir/dir1/dir2
			exists, err := f.Remote.DirExists(deepNestedDir)
			So(err, ShouldBeNil)
			So(exists, ShouldBeFalse)

			//check local/cache RmDir/dir1/file
			So(f.CheckLocalEntryNotExists(nestedFile), ShouldBeNil)

			// check remote RmDir/dir1/file
			exists, err = f.Remote.DirExists(nestedFile)
			So(err, ShouldBeNil)
			So(exists, ShouldBeFalse)
		})
	})
}
