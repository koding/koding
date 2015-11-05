package models

import (
	"strconv"
	"testing"
	"time"

	. "github.com/smartystreets/goconvey/convey"
)

func TestTimeSegmentor(t *testing.T) {
	Convey("time segmentor should not fail", t, func() {
		ts := NewTimeSegmentor(30)
		expectedSegment := time.Now().Minute() / 30
		So(ts.GetCurrentSegment(), ShouldEqual, strconv.Itoa(expectedSegment))
		So(ts.GetNextSegment(), ShouldEqual, strconv.Itoa((expectedSegment+1)%2))
	})

}
