package fs

import (
	"testing"

	"github.com/jacobsa/fuse/fuseops"
	. "github.com/smartystreets/goconvey/convey"
)

func TestNodeIDGen(t *testing.T) {
	Convey("It should initialize with last id set to root id", t, func() {
		i := NewNodeIDGen()
		So(i.LastID, ShouldEqual, fuseops.RootInodeID)
	})

	Convey("It should initialize with last id set to root id", t, func() {
		i := NewNodeIDGen()
		So(i.Next(), ShouldEqual, 2)
	})
}
