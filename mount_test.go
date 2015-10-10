package main

import (
	"bytes"
	"fmt"
	"os"
	"path/filepath"
	"testing"

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
	askDir := filepath.Join("asktocreate")

	// Nuke and create the temp dir for a fresh env
	os.RemoveAll(askDir)
	os.MkdirAll(askDir, 0655)

	Convey("Should not do anything if the folder already exists", t, func() {
		var out, in bytes.Buffer
		// We're giving it an invalid input, so it would normally error out.
		// But, because the directory exists, it should *not* error out.
		fmt.Fprintf(&in, "foo\nbar\nbaz\nbam\n")
		err := askToCreate(askDir, &out, &in)
		So(err, ShouldBeNil)
	})

	os.RemoveAll(askDir)

	Convey("Should create the folder if the user chooses yes", t, func() {
		var out, in bytes.Buffer
		fmt.Fprintf(&in, "yes\n")
		err := askToCreate(askDir, &out, &in)
		So(err, ShouldBeNil)
		So(exists(askDir), ShouldBeTrue)
	})

	Convey("Should not create the folder and error, if the user chooses no", t, func() {
		var out, in bytes.Buffer
		fmt.Fprintf(&in, "no\n")
		err := askToCreate(askDir, &out, &in)
		So(err, ShouldBeNil)
		So(exists(askDir), ShouldBeFalse)
	})

	Convey("Should retry asking the user, for unexpected input", t, func() {
		var out, in bytes.Buffer
		fmt.Fprintf(&in, "foo\nbar\nyes\n")
		err := askToCreate(askDir, &out, &in)
		So(err, ShouldBeNil)
		So(exists(askDir), ShouldBeFalse)
	})
}
