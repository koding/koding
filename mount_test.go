package main

import (
	"bytes"
	"fmt"
	"os"
	"path/filepath"
	"testing"

	"github.com/koding/klient/cmd/klientctl/klientctlerrors"
	. "github.com/smartystreets/goconvey/convey"
)

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

			var in, out bytes.Buffer
			// We're giving it an invalid input, so it would normally error out.
			// But, because the directory exists, it should *not* error out.
			fmt.Fprintf(&in, "foo\nbar\nbaz\nbam\n")
			err := askToCreate(askDir, &in, &out)
			So(err, ShouldBeNil)
		})

		Convey("Should create the folder if the user chooses yes", func() {
			os.RemoveAll(askDir)

			var in, out bytes.Buffer
			fmt.Fprintf(&in, "yes\n")
			err := askToCreate(askDir, &in, &out)
			So(err, ShouldBeNil)
			So(exists(askDir), ShouldBeTrue)
		})

		Convey("Should not create the folder and error, if the user chooses no", func() {
			os.RemoveAll(askDir)

			var in, out bytes.Buffer
			fmt.Fprintf(&in, "no\n")
			err := askToCreate(askDir, &in, &out)
			So(err, ShouldEqual, klientctlerrors.ErrUserCancelled)
			So(exists(askDir), ShouldBeFalse)
		})

		Convey("Should retry asking the user if unexpected input, 3 times", func() {
			os.RemoveAll(askDir)

			var in, out bytes.Buffer
			fmt.Fprint(&in, "foo\nbar\nyes\n")
			err := askToCreate(askDir, &in, &out)
			So(err, ShouldBeNil)
			So(exists(askDir), ShouldBeTrue)
		})

		Convey("Should fail after retrying 4 times", func() {
			os.RemoveAll(askDir)

			var in, out bytes.Buffer
			fmt.Fprintf(&in, "foo\nbar\nbaz\nyes\n")
			err := askToCreate(askDir, &in, &out)
			So(err, ShouldNotBeNil)
			So(exists(askDir), ShouldBeFalse)
		})
	})
}
