package main

import (
	"bytes"
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/koding/logging"

	"koding/klient/remote/restypes"
	//"koding/klientctl/klientctlerrors"
	"koding/klientctl/list"
	"koding/klientctl/util/testutil"
	"koding/mountcli"

	. "github.com/smartystreets/goconvey/convey"
)

var discardLogger logging.Logger

type mockMountFinder struct {
	Path           string
	Error          error
	LastCalledWith string
}

func (m *mockMountFinder) FindMountedPathByName(s string) (string, error) {
	m.LastCalledWith = s
	return m.Path, m.Error
}

func init() {
	discardLogger = logging.NewLogger("test")
	discardLogger.SetHandler(logging.NewWriterHandler(ioutil.Discard))
}

func TestUnmountRemoveMountFolder(t *testing.T) {
	Convey("Given a folder with a file in it", t, func() {
		tmpDir, err := ioutil.TempDir("", "non-empty-folder")
		So(err, ShouldBeNil)
		defer os.RemoveAll(tmpDir)

		err = ioutil.WriteFile(filepath.Join(tmpDir, "file"), []byte("foo"), 0755)
		So(err, ShouldBeNil)

		var stdout bytes.Buffer

		c := &UnmountCommand{
			Options: UnmountOptions{
				Path: tmpDir,
			},
			Log:         discardLogger,
			Stdout:      &stdout,
			fileRemover: os.Remove,
		}

		Convey("It should fail removing the folder", func() {
			So(c.removeMountFolder(), ShouldNotBeNil)
		})

		Convey("It should print a warning", func() {
			c.removeMountFolder()
			So(stdout.String(), ShouldContainSubstring, UnmountFailedRemoveMountPath)
		})

		os.RemoveAll(tmpDir)
	})

	Convey("Given a folder with a dir in it", t, func() {
		tmpDir, err := ioutil.TempDir("", "non-empty-folder")
		So(err, ShouldBeNil)
		defer os.RemoveAll(tmpDir)

		err = os.Mkdir(filepath.Join(tmpDir, "embedded-dir"), 0755)
		So(err, ShouldBeNil)

		var stdout bytes.Buffer
		c := &UnmountCommand{
			Options: UnmountOptions{
				Path: tmpDir,
			},
			Log:         discardLogger,
			Stdout:      &stdout,
			fileRemover: os.Remove,
		}

		Convey("Then it should fail removing the folder", func() {
			So(c.removeMountFolder(), ShouldNotBeNil)
		})

		Convey("It should print a warning", func() {
			c.removeMountFolder()
			So(stdout.String(), ShouldContainSubstring, UnmountFailedRemoveMountPath)
		})

		os.RemoveAll(tmpDir)
	})

	Convey("Given a folder that is set as NeverRemoved", t, func() {
		tmpDir, err := ioutil.TempDir("", "non-empty-folder")
		So(err, ShouldBeNil)
		defer os.RemoveAll(tmpDir)

		var stdout bytes.Buffer
		c := &UnmountCommand{
			Options: UnmountOptions{
				Path:        tmpDir,
				NeverRemove: []string{"/foo", "/bar", tmpDir},
			},
			Log:         discardLogger,
			Stdout:      &stdout,
			fileRemover: os.Remove,
		}

		Convey("Then it should fail removing the folder", func() {
			err := c.removeMountFolder()
			So(err, ShouldNotBeNil)
			So(strings.ToLower(err.Error()), ShouldContainSubstring, "restricted")
		})

		Convey("It should print a warning", func() {
			c.removeMountFolder()
			So(stdout.String(), ShouldContainSubstring, AttemptedRemoveRestrictedPath)
		})
	})

	Convey("Given no path", t, func() {
		var stdout bytes.Buffer
		c := &UnmountCommand{
			Log:         discardLogger,
			Stdout:      &stdout,
			fileRemover: os.Remove,
		}

		Convey("It should fail.", func() {
			err := c.removeMountFolder()
			So(err, ShouldNotBeNil)
			So(err.Error(), ShouldContainSubstring, "empty")
		})

		Convey("It should warn the user", func() {
			c.removeMountFolder()
			So(stdout.String(), ShouldContainSubstring, UnmountFailedRemoveMountPath)
		})
	})
}

func TestUnmountFindMountAndPath(t *testing.T) {
	Convey("Given an UnmountCommand", t, func() {
		fakeKlient := &testutil.FakeKlient{}
		var stdout bytes.Buffer
		c := &UnmountCommand{
			Klient: fakeKlient,
			Log:    discardLogger,
			Stdout: &stdout,
			mountFinder: &testutil.FakeMountcli{
				ReturnMountByPathErr: mountcli.ErrNoMountName,
			},
		}

		Convey("Given a machine name that does not exist", func() {
			c.Options.MountName = "bar"
			fakeKlient.ReturnInfos = []list.KiteInfo{list.KiteInfo{restypes.ListMachineInfo{
				VMName: "foo",
			}},
			}

			Convey("It should fail and inform the user", func() {
				err := c.findMountAndPath()
				So(err, ShouldNotBeNil)
				So(stdout.String(), ShouldContainSubstring, MachineNotFound)
			})
		})

		Convey("Given a machine that has mounts", func() {
			c.Options.MountName = "foo"
			fakeKlient.ReturnInfos = []list.KiteInfo{list.KiteInfo{restypes.ListMachineInfo{
				VMName: "foo",
				// Content doesn't matter, just length
				Mounts: []restypes.ListMountInfo{restypes.ListMountInfo{}},
			}},
			}

			Convey("It should not return an error", func() {
				So(c.findMountAndPath(), ShouldBeNil)
			})
		})

		Convey("Given a machine that has no mounts", func() {
			c.Options.MountName = "foo"
			fakeKlient.ReturnInfos = []list.KiteInfo{list.KiteInfo{restypes.ListMachineInfo{
				VMName: "foo",
				// Content doesn't matter, just length
				Mounts: []restypes.ListMountInfo{},
			}},
			}

			Convey("It should fail and inform the user", func() {
				err := c.findMountAndPath()
				So(err, ShouldNotBeNil)
				So(stdout.String(), ShouldContainSubstring, MountNotFound)
			})
		})
	})
}
