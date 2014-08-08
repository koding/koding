package topicfeed

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestMarkedAsTroll(t *testing.T) {
	Convey("while extracting topics", t, func() {
		Convey("duplicates should be returned as unique", func() {
			So(len(extractTopics("hi #topic #topic my topic")), ShouldEqual, 1)
		})
	})
}
