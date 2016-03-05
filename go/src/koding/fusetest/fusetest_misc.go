package fusetest

import (
	"fmt"
	"io/ioutil"
	"os"
	"os/exec"
	"path"
	"path/filepath"

	. "github.com/smartystreets/goconvey/convey"
)

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

func (f *Fusetest) TestCpOutToIn() {
	f.setupConvey("CpOutIn", func(dirPath string) {
		Convey("It should cp file from outside mount to inside", func() {
			fi, err := ioutil.TempFile("", "out")
			So(err, ShouldBeNil)

			_, err = fi.WriteString("Hello World!")
			So(err, ShouldBeNil)

			out := fi.Name()

			_, err = statFileCheck(out, 0600)
			So(err, ShouldBeNil)

			in := filepath.Join(dirPath, "in")

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
