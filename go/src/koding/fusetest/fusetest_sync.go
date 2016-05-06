package fusetest

import (
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"time"

	. "github.com/smartystreets/goconvey/convey"
)

func (f *Fusetest) TestSyncInterval() {
	f.setupConvey("SyncInterval", func(tmpDir string) {
		testDir1 := filepath.Join(f.fullMountPath(tmpDir), "foo", "bar", "baz")
		testDir2 := filepath.Join(f.fullMountPath(tmpDir), "boo", "far", "faz")
		testFiles1 := []string{
			filepath.Join(testDir1, "one"),
			filepath.Join(testDir1, "two"),
		}
		testFiles2 := []string{
			filepath.Join(testDir2, "three"),
			filepath.Join(testDir2, "four"),
		}

		So(os.MkdirAll(testDir1, 0755), ShouldBeNil)
		So(os.MkdirAll(testDir2, 0755), ShouldBeNil)
		for _, testFile := range append(testFiles1, testFiles2...) {
			So(ioutil.WriteFile(testFile, []byte(testFile), 0644), ShouldBeNil)
		}

		// Wait, so that the files are added to remote
		So(f.WaitForSync(), ShouldBeNil)

		Convey("It should copy created files after X seconds", func() {
			for _, testFile := range append(testFiles1, testFiles2...) {
				contents, err := f.Remote.ReadFile(testFile)
				So(err, ShouldBeNil)
				So(contents, ShouldEqual, testFile)
			}
		})

		Convey("When some files are removed", func() {
			So(os.RemoveAll(testDir2), ShouldBeNil)

			// Wait, so that the files are removed from remote
			So(f.WaitForSync(), ShouldBeNil)

			Convey("It should remove the files after X seconds", func() {
				for _, testFile := range testFiles2 {
					exists, err := f.Remote.FileExists(testFile)
					So(err, ShouldBeNil)
					So(exists, ShouldBeFalse)
				}
			})
		})
	})
}

// WaitForSync is a helper to simply block for the duration of a sync. In future
// upgrades it may change to block until the next sync is fully done.
func (f *Fusetest) WaitForSync() error {
	// Wait for the interval time, plus an estimated 3s of runtime.
	// 3s is just pulled from thin air, but it should be large enough
	// to reliably pass, even on large repos.
	waitTime := f.Opts.SyncIntervalOpts.Interval + 3*time.Second
	fmt.Printf(
		"\nPausing for %s to wait for OneWaySync changes to be propogated to Remote...\n",
		waitTime,
	)
	time.Sleep(waitTime)
	return nil
}
