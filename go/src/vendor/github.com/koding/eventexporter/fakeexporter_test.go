package eventexporter

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestFakeExporter(t *testing.T) {
	Convey("When using FakeExporter", t, func() {
		event := &Event{Name: "test"}

		fakeExporter := NewFakeExporter()
		err := fakeExporter.Send(event)

		Convey("Then it should save event for debugging", func() {
			So(err, ShouldBeNil)
			So(len(fakeExporter.Events), ShouldEqual, 1)
		})
	})
}
