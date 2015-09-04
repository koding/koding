package lock

import (
	"io/ioutil"
	"os"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestLock(t *testing.T) {
	Convey("", t, func() {
		mountPath, err := ioutil.TempDir("", "fuseklient")
		So(err, ShouldBeNil)

		Convey("It should get or create config folder", func() {
			configFolder, err := getOrCreateConfigFolder()
			So(err, ShouldBeNil)

			_, err = os.Stat(configFolder)
			So(err, ShouldBeNil)
		})

		lockFile, err := getLockFileName(mountPath)
		So(err, ShouldBeNil)

		Convey("It should return error if lock file already exists", func() {
			_, err = os.Create(lockFile)
			So(err, ShouldBeNil)

			So(Lock(mountPath), ShouldNotBeNil)

			defer os.Remove(lockFile)
		})

		Convey("It should lock mount", func() {
			os.Remove(lockFile)

			So(Lock(mountPath), ShouldBeNil)

			_, err = os.Stat(lockFile)
			So(err, ShouldBeNil)

			defer os.Remove(lockFile)
		})

		Convey("It should unlock mount", func() {
			os.Remove(lockFile)
			So(Lock(mountPath), ShouldBeNil)

			So(Unlock(mountPath), ShouldBeNil)

			_, err = os.Stat(lockFile)
			So(err, ShouldNotBeNil)
		})
	})
}
