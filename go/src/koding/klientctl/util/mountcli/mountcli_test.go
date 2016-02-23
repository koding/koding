package mountcli

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

const inputA = `
mountname on /some/mount/path/foo/bar (osxfusefs, nodev, nosuid, synchronous, mounted by username)
`

// generateBinRunner returns a binRunner func which simply returns whatever string
// it was originally given.
func generateBinRunner(s string, err error) func(string) (string, error) {
	return func(string) (string, error) {
		return s, err
	}
}

func TestFindMountedPathByName(t *testing.T) {
	Convey("It should return the matching path", t, func() {
		m := &Mount{binRunner: generateBinRunner(inputA, nil)}

		path, err := m.FindMountedPathByName("mountname")
		So(err, ShouldBeNil)
		So(path, ShouldEqual, "/some/mount/path/foo/bar")
	})

	Convey("It should return empty on no match", t, func() {
		m := &Mount{binRunner: generateBinRunner(inputA, nil)}

		path, err := m.FindMountedPathByName("nomatch")
		So(err, ShouldBeNil)
		So(path, ShouldEqual, "")
	})
}
