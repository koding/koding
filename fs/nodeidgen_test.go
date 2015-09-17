package fs

import (
	"testing"

	"github.com/jacobsa/fuse/fuseops"
	. "github.com/smartystreets/goconvey/convey"
)

func TestNodeIDGen(t *testing.T) {
	Convey("NewNodeIDGen", t, func() {
		Convey("It should initialize with last id set to root id", func() {
			i := NewNodeIDGen()
			So(i.LastID, ShouldEqual, fuseops.RootInodeID)
		})
	})

	Convey("NodeIDGen#Next", t, func() {
		Convey("It should generate new unique id", func() {
			i := NewNodeIDGen()
			So(i.Next(), ShouldEqual, 2)
		})
	})
}
