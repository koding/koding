package main

import (
	"bytes"
	"errors"
	"fmt"
	"io/ioutil"
	"koding/klient/remote/req"
	"os"
	"path/filepath"
	"testing"
	"time"

	"koding/klient/kiteerrortypes"
	"koding/klient/remote/restypes"
	klienttestutil "koding/klient/testutil"
	"koding/klient/util"
	"koding/klientctl/klientctlerrors"
	"koding/klientctl/list"
	"koding/klientctl/util/testutil"

	"github.com/koding/kite/dnode"

	. "github.com/smartystreets/goconvey/convey"
)

func init() {
	defaultHealthChecker = NewDefaultHealthChecker(klienttestutil.DiscardLogger)
}

// BlockingIO is a struct primarily for mocking the behavior of Stdin. Stdin blocks
// the Reader while waiting for input, so mocking Stdin with a typical Buffer can
// often be problematic, because the buffer will return empty of there is no input.
//
// BlockingIO works around this by using a channel to block the read until a write
// exists.
type BlockingIO struct {
	C chan []byte
}

func NewBlockingIO() *BlockingIO {
	return &BlockingIO{
		C: make(chan []byte, 5),
	}
}

func (io *BlockingIO) Close() error {
	close(io.C)
	// No errors to return atm, but keeping the API consistent with other Close()
	return nil
}

func (io *BlockingIO) Read(p []byte) (int, error) {
	cp := <-io.C
	l := len(cp)
	// if p wasn't big enough to fit all the data from cp, add the rest back onto the
	// channel. The next Read will consume it. Note that this is racey, but it's good
	// enough for unit tests. If we encounter the obvious race condition(s), we can
	// add a simple lock for this.
	if len(cp) > len(p) {
		l := len(p)
		io.C <- cp[l:]
	}
	for i := 0; i < l; i++ {
		p[i] = cp[i]
	}
	return l, nil
}

func (io *BlockingIO) Write(p []byte) (int, error) {
	io.C <- p[:]
	return len(p), nil
}

func (io *BlockingIO) SleepyWriteString(t time.Duration, ss ...string) {
	for _, s := range ss {
		time.Sleep(t)
		fmt.Fprint(io, s)
	}
}

func (io *BlockingIO) SleepyWriteStringAndClose(t time.Duration, ss ...string) {
	io.SleepyWriteString(t, ss...)
	io.Close()
}

// Ignoring perm errors/etc, just using this as a simple shorthand for
// tests
func exists(p string) bool {
	if _, err := os.Stat(p); os.IsNotExist(err) {
		return false
	}

	return true
}

func TestAskToCreate(t *testing.T) {
	tmpDir := filepath.Join("_test", "tmp")
	askDir := filepath.Join(tmpDir, "asktocreate")

	Convey("askToCreate", t, func() {
		Convey("Should not do anything if the folder already exists", func() {
			os.RemoveAll(askDir)
			os.MkdirAll(askDir, 0755)

			var out bytes.Buffer
			in := NewBlockingIO()
			// We're giving it an invalid input, so it would normally error out.
			// But, because the directory exists, it should *not* error out.
			go in.SleepyWriteStringAndClose(
				10*time.Millisecond,
				"foo\n", "bar\n", "baz\n", "bam\n",
			)
			err := askToCreate(askDir, in, &out)
			So(err, ShouldBeNil)
		})

		Convey("Should create the folder if the user chooses yes", func() {
			os.RemoveAll(askDir)

			var out bytes.Buffer
			in := NewBlockingIO()
			go in.SleepyWriteStringAndClose(
				10*time.Millisecond,
				"yes\n",
			)
			err := askToCreate(askDir, in, &out)
			So(err, ShouldBeNil)
			So(exists(askDir), ShouldBeTrue)

			fi, err := os.Stat(askDir)
			So(err, ShouldBeNil)
			So(fi.Mode(), ShouldEqual, os.FileMode(0755)|os.ModeDir)
		})

		Convey("Should not create the folder and error, if the user chooses no", func() {
			os.RemoveAll(askDir)

			var out bytes.Buffer
			in := NewBlockingIO()
			go in.SleepyWriteStringAndClose(
				10*time.Millisecond,
				"no\n",
			)
			err := askToCreate(askDir, in, &out)
			So(err, ShouldEqual, klientctlerrors.ErrUserCancelled)
			So(exists(askDir), ShouldBeFalse)
		})

		Convey("Should retry asking the user if unexpected input, 3 times", func() {
			os.RemoveAll(askDir)

			var out bytes.Buffer
			in := NewBlockingIO()
			go in.SleepyWriteStringAndClose(
				10*time.Millisecond,
				"foo\n", "bar\n", "yes\n",
			)
			err := askToCreate(askDir, in, &out)
			So(err, ShouldBeNil)
			So(exists(askDir), ShouldBeTrue)
		})

		Convey("Should fail after retrying 4 times", func() {
			os.RemoveAll(askDir)

			var out bytes.Buffer
			in := NewBlockingIO()
			go in.SleepyWriteStringAndClose(
				10*time.Millisecond,
				"foo\n", "bar\n", "baz\n", "yes\n",
			)
			err := askToCreate(askDir, in, &out)
			So(err, ShouldNotBeNil)
			So(exists(askDir), ShouldBeFalse)
		})
	})
}

func TestCachePath(t *testing.T) {
	Convey("It should store cache folder under config in home", t, func() {
		expectedPath := filepath.Join(ConfigFolder, "t.cache")

		path := getCachePath("t")
		So(path, ShouldEqual, expectedPath)
	})
}

func TestMountCreateMountDir(t *testing.T) {
	Convey("Given a nested path that does not exist", t, func() {
		tmpDir, err := ioutil.TempDir("", "non-empty-folder")
		So(err, ShouldBeNil)
		defer os.RemoveAll(tmpDir)
		mountDir := filepath.Join(tmpDir, "foo", "bar", "mountDir")

		var stdout bytes.Buffer
		c := &MountCommand{
			Options: MountOptions{
				LocalPath: mountDir,
			},
			Log:    discardLogger,
			Stdout: &stdout,
		}

		Convey("It should create the path", func() {
			err := c.createMountDir()
			So(err, ShouldBeNil)

			fi, err := os.Stat(mountDir)
			So(err, ShouldBeNil)
			So(fi.Mode(), ShouldEqual, os.FileMode(0755)|os.ModeDir)
		})
	})

	Convey("Given a dir that exists", t, func() {
		tmpDir, err := ioutil.TempDir("", "non-empty-folder")
		So(err, ShouldBeNil)
		defer os.RemoveAll(tmpDir)

		// Ensure that it does exist
		_, err = os.Stat(tmpDir)
		So(err, ShouldBeNil)

		var stdout bytes.Buffer
		c := &MountCommand{
			Options: MountOptions{
				LocalPath: tmpDir,
			},
			Log:    discardLogger,
			Stdout: &stdout,
		}

		Convey("It should return an error", func() {
			err := c.createMountDir()
			So(err, ShouldNotBeNil)
			So(err.Error(), ShouldContainSubstring, "already exists")
		})

		Convey("It should inform the user", func() {
			c.createMountDir()
			So(stdout.String(), ShouldContainSubstring, CannotMountPathExists)
		})
	})

	Convey("Given a file that exists", t, func() {
		tmpDir, err := ioutil.TempDir("", "non-empty-folder")
		So(err, ShouldBeNil)
		defer os.RemoveAll(tmpDir)
		tmpFile := filepath.Join(tmpDir, "file")

		err = ioutil.WriteFile(tmpFile, []byte("foo"), 0755)
		So(err, ShouldBeNil)

		// Ensure that it does exist
		_, err = os.Stat(tmpFile)
		So(err, ShouldBeNil)

		var stdout bytes.Buffer
		c := &MountCommand{
			Options: MountOptions{
				LocalPath: tmpFile,
			},
			Log:    discardLogger,
			Stdout: &stdout,
		}

		Convey("It should return an error", func() {
			err := c.createMountDir()
			So(err, ShouldNotBeNil)
			So(err.Error(), ShouldContainSubstring, "already exists")
		})

		Convey("It should inform the user", func() {
			c.createMountDir()
			So(stdout.String(), ShouldContainSubstring, CannotMountPathExists)
		})
	})
}

func TestMountFindMachineName(t *testing.T) {
	Convey("Given a machine is not found", t, func() {
		var stdout bytes.Buffer
		c := &MountCommand{
			Klient: &testutil.FakeKlient{
				ReturnInfos: []list.KiteInfo{{ListMachineInfo: restypes.ListMachineInfo{
					VMName: "foo",
				}},
				},
			},
			Options: MountOptions{
				Name:      "bar", // the name we're looking for
				LocalPath: "foo", // fake folder name
			},
			Log:    discardLogger,
			Stdout: &stdout,
		}

		Convey("It should inform the user", func() {
			// Note that if, for some reason, findMachineName does not properly return
			// an error, this call will likely panic. The reason is that we do not have
			// the entirety of the command mocked/setup here. Rsync, Progress,
			// healthchecker, path cleanup, listing, etc.
			exit, err := c.Run()
			So(err, ShouldNotBeNil)
			So(exit, ShouldNotEqual, 0)
			So(stdout.String(), ShouldContainSubstring, MachineNotFound)
		})
	})
}

func TestMountCommandRemoteCache(t *testing.T) {
	Convey("Given a process error is returned", t, func() {
		fakeKlient := &testutil.FakeKlient{
			ReturnRemoteCacheErr: util.KiteErrorf(kiteerrortypes.ProcessError, "Err msg"),
		}
		var b bytes.Buffer
		c := MountCommand{
			Stdout: &b,
			Klient: fakeKlient,
		}

		Convey("It should print RemoteProcessFailed", func() {
			err := c.callRemoteCache(req.Cache{}, func(*dnode.Partial) {})
			So(err, ShouldNotBeNil)
			So(b.String(), ShouldContainSubstring, "A requested process on the remote")
		})
	})

	Convey("Given a non-process error is returned", t, func() {
		fakeKlient := &testutil.FakeKlient{
			ReturnRemoteCacheErr: errors.New("Err msg"),
		}
		var b bytes.Buffer
		c := MountCommand{
			Stdout: &b,
			Klient: fakeKlient,
		}

		Convey("It should not print RemoteProcessFailed", func() {
			err := c.callRemoteCache(req.Cache{}, func(*dnode.Partial) {})
			So(err, ShouldNotBeNil)
			So(b.String(), ShouldNotContainSubstring, "A requested process on the remote")
		})
	})
}
