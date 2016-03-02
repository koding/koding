package fusetest

import (
	"fmt"
	"io/ioutil"
	"os"
	"os/exec"
	"path/filepath"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func testGitClone(t *testing.T, mountDir string) {
	Convey("Git", t, createDir(mountDir, "GitClone", func(dirPath string) {
		Convey("It should clone repo", func() {
			clone := func(dir string) error {
				cmd := exec.Command("git", "clone", "-q", "https://github.com/sent-hil/bitesized", dir)
				_, err := cmd.Output()
				return err
			}

			md5 := func(dir string) (string, error) {
				cmd := exec.Command("bash", "-c", fmt.Sprintf("ls %s | md5", dir))
				output, err := cmd.Output()

				return string(output), err
			}

			So(clone(dirPath), ShouldBeNil)

			Convey("It should compare contents of mount & outside repos", func() {
				// clone git repo to outside mount
				temp, err := ioutil.TempDir("", "")
				So(err, ShouldBeNil)

				So(clone(temp), ShouldBeNil)

				// compare if md5 of inside mount repo is same as outside mount repo
				ta, err := md5(filepath.Join(dirPath, "bitesized"))
				So(err, ShouldBeNil)

				tb, err := md5(filepath.Join(temp, "bitesized"))
				So(err, ShouldBeNil)

				So(ta, ShouldEqual, tb)

				Reset(func() { os.RemoveAll(temp) })
			})
		})
	}))
}
