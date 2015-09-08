package fs

import (
	"testing"

	"github.com/jacobsa/fuse/fuseutil"
	. "github.com/smartystreets/goconvey/convey"
)

func TestFileSystem(t *testing.T) {
	Convey("It should implement all fuse.FileSystem methods", t, func() {
		var _ fuseutil.FileSystem = (*FileSystem)(nil)
	})
}
