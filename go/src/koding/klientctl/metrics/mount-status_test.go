package metrics

import (
	"io/ioutil"
	"os"
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

			Convey("It should remove file", func() {
				So(m.Remove(), ShouldBeNil)
				_, err := os.Open(m.filepath())
				So(os.IsNotExist(err), ShouldBeTrue)
			})
		})
	})
}
