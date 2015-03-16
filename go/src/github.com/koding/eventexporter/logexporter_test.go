package eventexporter

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestLogExporter(t *testing.T) {
	Convey("", t, func() {
		event := &Event{Name: "test"}

		logExporter := NewLogExporter()
		err := logExporter.Send(event)

		So(err, ShouldBeNil)
		So(len(logExporter.Events), ShouldEqual, 1)
	})
}
