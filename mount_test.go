package main

import (
	"bytes"
	"fmt"
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/koding/klientctl/klientctlerrors"
	. "github.com/smartystreets/goconvey/convey"
)

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
