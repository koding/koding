package transport

import (
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"syscall"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestDiskTransport(t *testing.T) {
	var _ Transport = (*DiskTransport)(nil)
}

func TestNewDiskTransport(t *testing.T) {
	Convey("NewDiskTransport", t, func() {
		Convey("It should create temp dir if no path is specified", func() {
			dt, err := NewDiskTransport("")
			So(err, ShouldBeNil)
			So(dt.LocalPath, ShouldNotEqual, "")
			statDirCheck(dt.LocalPath)
		})

		Convey("It should use path if specified", func() {
			mountDir, err := ioutil.TempDir("", "mounttest")
			So(err, ShouldBeNil)

			dt, err := NewDiskTransport(mountDir)
			So(err, ShouldBeNil)
			So(dt.LocalPath, ShouldEqual, mountDir)
		})
	})
}

func TestDTCreateDir(t *testing.T) {
	Convey("CreateDir", t, func() {
		dt, err := NewDiskTransport("")
		So(err, ShouldBeNil)

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
	Convey("ReadDir", t, func() {
		dt, err := NewDiskTransport("")
		So(err, ShouldBeNil)

		// create dir with a dir inside
		err = dt.CreateDir("/1/a", 0700)
		So(err, ShouldBeNil)

		// create file inside dir
		err = dt.WriteFile("/1/b", []byte{})
		So(err, ShouldBeNil)

		Convey("It should return nested entires of dir", func() {
			res, err := dt.ReadDir("/", true, []string{})
			So(err, ShouldBeNil)

			entries := res.Files
			So(len(entries), ShouldEqual, 3)

			Convey("It should create top level dir", func() {
				So(entries[0].IsDir, ShouldEqual, true)
				So(entries[0].Name, ShouldEqual, "1")

				Convey("It should remove remote path prefix", func() {
					So(entries[0].FullPath, ShouldEqual, "/1")
				})
			})
		})

		Convey("It should create return entries of dir", func() {
			res, err := dt.ReadDir("/1", false, []string{})
			So(err, ShouldBeNil)

			entries := res.Files
			So(len(entries), ShouldEqual, 2)

			Convey("It should create return dir with info", func() {
				So(entries[0].IsDir, ShouldEqual, true)
				So(entries[0].Name, ShouldEqual, "a")

				Convey("It should remove remote path prefix", func() {
					So(entries[0].FullPath, ShouldEqual, "/1/a")
				})
			})

			Convey("It should create return file with info", func() {
				So(entries[1].IsDir, ShouldEqual, false)
				So(entries[1].Name, ShouldEqual, "b")

				Convey("It should remove remote path prefix", func() {
					So(entries[1].FullPath, ShouldEqual, "/1/b")
				})
			})
		})
	})
}

func TestDTRename(t *testing.T) {
	Convey("Rename", t, func() {
		dt, err := NewDiskTransport("")
		So(err, ShouldBeNil)

		err = dt.WriteFile("file", []byte("hello world!"))
		So(err, ShouldBeNil)
		statFileCheck(dt.fullPath("file"), 0644)

		err = dt.Rename("file", "file1")
		So(err, ShouldBeNil)

		Convey("It should change name of entry from old to new", func() {
			res, err := dt.ReadFile("file1")
			So(err, ShouldBeNil)
			So(string(res.Content), ShouldEqual, "hello world!")
		})

		Convey("It should remove old entry", func() {
			_, err = os.Stat(dt.fullPath("file"))
			So(err.Error(), ShouldContainSubstring, "no such file or directory")
		})
	})
}

func TestDTRemove(t *testing.T) {
	Convey("Remove", t, func() {
		dt, err := NewDiskTransport("")
		So(err, ShouldBeNil)

		err = dt.WriteFile("file", []byte("hello world!"))
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
	Convey("ReadFile", t, func() {
		dt, err := NewDiskTransport("")
		So(err, ShouldBeNil)

		Convey("It should read contents of file", func() {
			err := dt.WriteFile("file", []byte("hello world!"))
			So(err, ShouldBeNil)

			res, err := dt.ReadFile("file")
			So(err, ShouldBeNil)
			So(string(res.Content), ShouldEqual, "hello world!")
		})
	})
}

func TestDTWriteFile(t *testing.T) {
	Convey("WriteFile", t, func() {
		dt, err := NewDiskTransport("")
		So(err, ShouldBeNil)

		Convey("It should write file with contents", func() {
			err := dt.WriteFile("1", []byte{1})
			So(err, ShouldBeNil)
			statFileCheck(dt.fullPath("1"), 0644)
		})
	})
}

func TestDTExec(t *testing.T) {
	Convey("Exec", t, func() {
		dt, err := NewDiskTransport("")
		So(err, ShouldBeNil)

		Convey("It should run command and return response", func() {
			// write file so we can check it with exec
			err := dt.WriteFile("/file", []byte{})
			So(err, ShouldBeNil)

			cmd := fmt.Sprintf("ls %s", dt.LocalPath)
			res, err := dt.Exec(cmd)
			So(err, ShouldBeNil)
			So(res.Stdout, ShouldEqual, "file\n")
			So(res.Stderr, ShouldEqual, "")
			So(res.ExitStatus, ShouldEqual, 0)
		})
	})
}

func TestDTGetDiskInfo(t *testing.T) {
	Convey("GetDiskInfo", t, func() {
		dt, err := NewDiskTransport("")
		So(err, ShouldBeNil)

		stfs := syscall.Statfs_t{}
		err = syscall.Statfs(dt.LocalPath, &stfs)
		So(err, ShouldBeNil)

		Convey("It should return disk info", func() {
			res, err := dt.GetDiskInfo("/")
			So(err, ShouldBeNil)
			So(res.BlockSize, ShouldEqual, uint32(stfs.Bsize))
			So(res.BlocksTotal, ShouldEqual, stfs.Blocks)
			So(res.BlocksFree, ShouldEqual, stfs.Bfree)
			So(res.BlocksUsed, ShouldEqual, (res.BlocksTotal - res.BlocksFree))
		})
	})
}

func TestDTGetInfo(t *testing.T) {
	Convey("GetInfo", t, func() {
		dt, err := NewDiskTransport("")
		So(err, ShouldBeNil)

		Convey("It should return info for root entry", func() {
			res, err := dt.GetInfo("/")
			So(err, ShouldBeNil)
			So(res.Exists, ShouldBeTrue)
			So(res.Name, ShouldEqual, filepath.Base(dt.LocalPath))
		})

		Convey("It should return info for dir", func() {
			err := dt.CreateDir("/dir", 0700)
			So(err, ShouldBeNil)

			res, err := dt.GetInfo("/dir")
			So(err, ShouldBeNil)
			So(res.Exists, ShouldBeTrue)
			So(res.Name, ShouldEqual, "dir")
			So(res.IsDir, ShouldEqual, true)

			Convey("It should remove remote path prefix", func() {
				So(res.FullPath, ShouldEqual, "/dir")
			})
		})

		Convey("It should return info for file", func() {
			err := dt.WriteFile("/file", []byte{})
			So(err, ShouldBeNil)

			res, err := dt.GetInfo("/file")
			So(err, ShouldBeNil)
			So(res.Exists, ShouldBeTrue)
			So(res.Name, ShouldEqual, "file")
			So(res.IsDir, ShouldEqual, false)

			Convey("It should remove remote path prefix from file path", func() {
				So(res.FullPath, ShouldEqual, "/file")
			})
		})
	})
}

///// Helpers

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
