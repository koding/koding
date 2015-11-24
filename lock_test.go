package fuseklient

import (
	"io/ioutil"
	"os"
	"path/filepath"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestLock(t *testing.T) {
	Convey("", t, func() {
		var err error

		// use temp dir for config folder or tests will fail when there's a mount
		lockFolderName, err = ioutil.TempDir("", "fuseklientconfig")
		So(err, ShouldBeNil)

		mountPath, err := ioutil.TempDir("", "fuseklient")
		So(err, ShouldBeNil)

		lockFile, err := getLockFileName(mountPath)
		So(err, ShouldBeNil)

		Convey("It should get or create config folder", func() {
			configFolder, err := getOrCreateConfigFolder()
			So(err, ShouldBeNil)

			_, err = os.Stat(configFolder)
			So(err, ShouldBeNil)
		})

		Convey("It should return error if lock file already exists", func() {
			_, err = os.Create(lockFile)
			So(err, ShouldBeNil)

			So(Lock(mountPath, "machine"), ShouldNotBeNil)
		})

		Convey("It should lock mount", func() {
			err := Lock(mountPath, "machine")
			So(err, ShouldBeNil)

			_, err = os.Stat(lockFile)
			So(err, ShouldBeNil)

			Convey("It should write machine name to file contents", func() {
				contents, err := ioutil.ReadFile(lockFile)
				So(err, ShouldBeNil)
				So(string(contents), ShouldEqual, "machine")
			})
		})

		Convey("It should unlock mount", func() {
			err := Lock(mountPath, "machine")
			So(err, ShouldBeNil)

			err = Unlock(mountPath)
			So(err, ShouldBeNil)

			_, err = os.Stat(lockFile)
			So(err, ShouldNotBeNil)
		})

		Convey("GetMachineMountedForPath", func() {
			Convey("It should return list of locks", func() {
				err := Lock(mountPath, "machine")
				So(err, ShouldBeNil)

				locks, err := GetMountedPathsFromLocks()
				So(err, ShouldBeNil)
				So(len(locks), ShouldEqual, 1)
			})
		})

		Convey("GetRelativeMountPath", func() {
			Convey("It should return empty string if local path is same as mount", func() {
				err := Lock(mountPath, "machine")
				So(err, ShouldBeNil)

				relativePath, err := GetRelativeMountPath(mountPath)
				So(err, ShouldBeNil)
				So(relativePath, ShouldEqual, "")
			})

			Convey("It should return relative path if local path is inside the mount", func() {
				err := Lock(mountPath, "machine")
				So(err, ShouldBeNil)

				nestedMountedpath := filepath.Join(mountPath, "nested", "onelevel")
				relativePath, err := GetRelativeMountPath(nestedMountedpath)
				So(err, ShouldBeNil)
				So(relativePath, ShouldEqual, filepath.Join("nested", "onelevel"))
			})

			Convey("It should return error if local path is not inside mount", func() {
				_, err := GetRelativeMountPath(filepath.Join("/", "random"))
				So(err, ShouldEqual, ErrNotInMount)
			})
		})

		Convey("GetMountedPathsFromLocks", func() {
			Convey("It should return machine name for mount", func() {
				err := Lock(mountPath, "machine")
				So(err, ShouldBeNil)

				machineName, err := GetMachineMountedForPath(mountPath)
				So(err, ShouldBeNil)
				So(machineName, ShouldEqual, "machine")
			})

			Convey("It should return error if local path is not inside mount", func() {
				_, err = GetMachineMountedForPath(mountPath)
				So(err, ShouldEqual, ErrNotInMount)
			})
		})

		defer os.Remove(lockFile)
	})
}
