package mountcli

import (
	"path/filepath"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

const inputA = `
mount1 on /path/mount1 (osxfusefs, nodev, nosuid, synchronous, mounted by username)
mount2 on /path/mount2 (osxfusefs, nodev, nosuid, synchronous, mounted by username)
`

// generateBinRunner returns a binRunner func which simply returns whatever string
// it was originally given.
func generateBinRunner(s string, err error) func(string) (string, error) {
	return func(string) (string, error) {
		return s, err
	}
}

func TestMount(t *testing.T) {
	Convey("Mount", t, func() {
		m := &Mountcli{binRunner: generateBinRunner(inputA, nil)}

		Convey("GetAllMountedPaths", func() {
			Convey("It should return all matching paths", func() {
				paths, err := m.GetAllMountedPaths()
				So(err, ShouldBeNil)
				So(paths, ShouldResemble, []string{"/path/mount1", "/path/mount2"})
			})
		})

		Convey("FindMountedPathByName", func() {
			Convey("It should return the matching path", func() {
				path, err := m.FindMountedPathByName("mount1")
				So(err, ShouldBeNil)
				So(path, ShouldEqual, "/path/mount1")
			})

			Convey("It should return err on no match", func() {
				_, err := m.FindMountedPathByName("nomatch")
				So(err, ShouldEqual, ErrNoMountName)
			})
		})

		Convey("GetMachineMountedForPath", func() {
			Convey("It should return the matching path", func() {
				machine, err := m.FindMountNameByPath("/path/mount1")
				So(err, ShouldBeNil)
				So(machine, ShouldEqual, "mount1")

				machine, err = m.FindMountNameByPath("/path/mount2")
				So(err, ShouldBeNil)
				So(machine, ShouldEqual, "mount2")
			})

			Convey("It should return err on no match", func() {
				_, err := m.FindMountNameByPath("/unknownpath")
				So(err, ShouldEqual, ErrNoMountPath)
			})
		})

		mounts, err := m.GetAllMountedPaths()
		So(err, ShouldBeNil)
		So(len(mounts), ShouldBeGreaterThan, 0)

		m1 := mounts[0]

		Convey("GetRelativeMountPath", func() {
			Convey("It should return empty string if path is same as mount", func() {
				relative, err := m.GetRelativeMountPath(m1)
				So(err, ShouldBeNil)
				So(relative, ShouldEqual, "")
			})

			Convey("It should return relative path if path is inside the mount", func() {
				relative, err := m.GetRelativeMountPath(filepath.Join(m1, "a/b/c"))
				So(err, ShouldBeNil)
				So(relative, ShouldEqual, "a/b/c")
			})

			Convey("It should return error if path is not inside mount", func() {
				_, err := m.GetRelativeMountPath("unknownpath")
				So(err, ShouldEqual, ErrNotInMount)
			})
		})

		Convey("IsPathInMountedPath", func() {
			Convey("It should return false if path is not inside mount", func() {
				inside, err := m.IsPathInMountedPath("unknownpath")
				So(err, ShouldBeNil)
				So(inside, ShouldEqual, false)
			})

			Convey("It should return true if path is inside mount", func() {
				inside, err := m.IsPathInMountedPath(filepath.Join(m1, "a"))
				So(err, ShouldBeNil)
				So(inside, ShouldEqual, true)
			})
		})
	})
}
