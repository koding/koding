package eventexporter

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestLogExporter(t *testing.T) {
	Convey("When using LogExporter", t, func() {
		event := &Event{Name: "test"}

		logExporter := NewLogExporter()
		err := logExporter.Send(event)

		Convey("Then it should save event for debugging", func() {
			So(err, ShouldBeNil)
			So(len(logExporter.Events), ShouldEqual, 1)
		})
	})
}
