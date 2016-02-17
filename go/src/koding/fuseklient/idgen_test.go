package fuseklient

import (
	"testing"

	"github.com/jacobsa/fuse/fuseops"
	. "github.com/smartystreets/goconvey/convey"
)

func TestNodeIDGen(t *testing.T) {
	Convey("NewNodeIDGen", t, func() {
		Convey("It should initialize with last id set to root id", func() {
			i := NewIDGen()
			So(i.LastID, ShouldEqual, fuseops.RootInodeID)
		})
	})

	Convey("NodeIDGen#Next", t, func() {
		Convey("It should generate new unique id", func() {
			i := NewIDGen()
			So(i.Next(), ShouldEqual, 2)
		})
	})
}

func TestHandleIDGen(t *testing.T) {
	Convey("NewHandleIDGen", t, func() {
		Convey("It should initialize with 0 set to LastId", func() {
			i := NewHandleIDGen()
			So(i.LastID, ShouldEqual, 0)
		})
	})

	Convey("HandleIDGen#Next", t, func() {
		Convey("It should generate new unique id", func() {
			i := NewHandleIDGen()
			So(i.Next(), ShouldEqual, 1)
		})
	})
}
