package main

import (
	"bytes"
	"fmt"
	"os"
	"path/filepath"
	"testing"

	"github.com/koding/klient/cmd/klientctl/errors"
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

	// Nuke and create the temp dir for a fresh env
	os.RemoveAll(askDir)
	os.MkdirAll(askDir, 0655)

	Convey("Should not do anything if the folder already exists", t, func() {
		var in, out bytes.Buffer
		// We're giving it an invalid input, so it would normally error out.
		// But, because the directory exists, it should *not* error out.
		fmt.Fprintf(&in, "foo\nbar\nbaz\nbam\n")
		err := askToCreate(askDir, &in, &out)
		So(err, ShouldBeNil)
	})

	os.RemoveAll(askDir)

	Convey("Should create the folder if the user chooses yes", t, func() {
		var in, out bytes.Buffer
		fmt.Fprintf(&in, "yes\n")
		err := askToCreate(askDir, &in, &out)
		So(err, ShouldBeNil)
		So(exists(askDir), ShouldBeTrue)
	})

	os.RemoveAll(askDir)

	Convey("Should not create the folder and error, if the user chooses no", t, func() {
		var in, out bytes.Buffer
		fmt.Fprintf(&in, "no\n")
		err := askToCreate(askDir, &in, &out)
		So(err, ShouldEqual, klientctlerrors.ErrUserCancelled)
		So(exists(askDir), ShouldBeFalse)
	})

	os.RemoveAll(askDir)

	Convey("Should retry asking the user if unexpected input, 3 times", t, func() {
		var in, out bytes.Buffer
		fmt.Fprint(&in, "foo\nbar\nyes\n")
		err := askToCreate(askDir, &in, &out)
		So(err, ShouldBeNil)
		So(exists(askDir), ShouldBeTrue)
	})

	os.RemoveAll(askDir)

	Convey("Should fail after retrying 4 times", t, func() {
		var in, out bytes.Buffer
		fmt.Fprintf(&in, "foo\nbar\nbaz\nyes\n")
		err := askToCreate(askDir, &in, &out)
		So(err, ShouldNotBeNil)
		So(exists(askDir), ShouldBeFalse)
	})
}
