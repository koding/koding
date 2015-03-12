package sender

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestLogSender(t *testing.T) {
	Convey("", t, func() {
		event := &Event{Name: "test"}

		logSender := NewLogSender()
		err := logSender.Send(event)

		So(err, ShouldBeNil)
		So(len(logSender.Events), ShouldEqual, 1)
	})
}
