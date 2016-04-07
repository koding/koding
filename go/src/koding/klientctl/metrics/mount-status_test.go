package metrics

import (
	"io/ioutil"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestMountStatus(t *testing.T) {
	Convey("MountStatus", t, func() {
		p, err := ioutil.TempDir("", "")
		So(err, ShouldBeNil)

		m := NewDefaultMountStatus(p)

		Convey("It should write to file", func() {
			So(m.Write(), ShouldBeNil)

			resp, err := ioutil.ReadFile(m.filepath())
			So(err, ShouldBeNil)
			So(string(resp), ShouldEqual, string(m.FileText))

			Convey("It should read from file", func() {
				So(m.CheckContents(), ShouldBeNil)
			})
		})
	})
}
