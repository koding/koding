package fusetest

import (
	"fmt"
	"io/ioutil"
	"os"
	"os/exec"
	"path/filepath"

	. "github.com/smartystreets/goconvey/convey"
)

func (f *Fusetest) TestRename() {
	f.setupConvey("Rename", func(dirName string) {
		Convey("It should rename dir", func() {
			oldPath := filepath.Join(dirName, "oldpath")
			newPath := filepath.Join(dirName, "newpath")

			So(os.Mkdir(f.fullMountPath(oldPath), 0700), ShouldBeNil)

			So(os.Rename(f.fullMountPath(oldPath), f.fullMountPath(newPath)), ShouldBeNil)

			_, err := os.Stat(f.fullMountPath(oldPath))
			So(err, ShouldNotBeNil)
			So(err.Error(), ShouldContainSubstring, "no such file or directory")

			statDirCheck(newPath)
		})

		Convey("It should rename file", func() {
			oldPath := filepath.Join(dirName, "file")
			newPath := filepath.Join(dirName, "renamedfile")

			err := ioutil.WriteFile(f.fullMountPath(oldPath), []byte("Hello World!"), 0700)
			So(err, ShouldBeNil)

			fi, err := statFileCheck(f.fullMountPath(oldPath), 0700)
			So(err, ShouldBeNil)
			So(os.Rename(f.fullMountPath(oldPath), f.fullMountPath(newPath)), ShouldBeNil)

			_, err = os.Stat(f.fullMountPath(oldPath))
			So(err, ShouldNotBeNil)
			So(err.Error(), ShouldContainSubstring, "no such file or directory")

			fi, err = statFileCheck(f.fullMountPath(newPath), 0700)
			So(err, ShouldBeNil)

			Convey("It should set new file size to be same as old file", func() {
				So(fi.Size(), ShouldEqual, 12) // size of content
			})

			Convey("It should new file content to be same as old file", func() {
				bytes, err := ioutil.ReadFile(f.fullMountPath(newPath))
				So(err, ShouldBeNil)
				So(string(bytes), ShouldEqual, "Hello World!")
			})
		})

		Convey("It should rename file to existing file", func() {
			file1 := filepath.Join(dirName, "file1")
			file2 := filepath.Join(dirName, "file2")

			// create file1
			err := ioutil.WriteFile(f.fullMountPath(file1), []byte("Hello"), 0700)
			So(err, ShouldBeNil)

			So(f.CheckLocalFileContents(file1, "Hello"), ShouldBeNil)

			// create file2
			err = ioutil.WriteFile(f.fullMountPath(file2), []byte("World!"), 0700)
			So(err, ShouldBeNil)

			So(f.CheckLocalFileContents(file2, "World!"), ShouldBeNil)

			// rename file2 to file1
			err = os.Rename(f.fullMountPath(file2), f.fullMountPath(file1))
			So(err, ShouldBeNil)

			// check file2 does not exist anymore
			_, err = os.Stat(f.fullMountPath(file2))
			So(err, ShouldNotBeNil)
			So(err.Error(), ShouldContainSubstring, "no such file or directory")

			_, err = statFileCheck(f.fullMountPath(file1), 0700)
			So(err, ShouldBeNil)

			// TODO: fix this
			//So(readFile(f.fullMountPath(file1), "World!"), ShouldBeNil)
		})
	})
}

func (f *Fusetest) TestCpOutToIn() {
	f.setupConvey("CpOutIn", func(dirName string) {
		Convey("It should cp file from outside mount to inside", func() {
			fi, err := ioutil.TempFile("", "out")
			So(err, ShouldBeNil)

			_, err = fi.WriteString("Hello World!")
			So(err, ShouldBeNil)

			out := fi.Name()

			_, err = statFileCheck(out, 0600)
			So(err, ShouldBeNil)

			in := filepath.Join(f.fullMountPath(dirName), "in")

			cmd := exec.Command("bash", "-c", fmt.Sprintf("cp %s %s", out, in))
			_, err = cmd.Output()
			So(err, ShouldBeNil)

			_, err = statFileCheck(in, 0600)
			So(err, ShouldBeNil)

			contents, err := f.Remote.ReadFile(in)
			So(err, ShouldBeNil)
			So(contents, ShouldEqual, "Hello World!")
		})
	})
}
