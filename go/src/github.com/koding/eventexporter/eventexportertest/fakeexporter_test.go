package eventexportertest

import (
	"testing"

	"github.com/koding/eventexporter"
)

func TestFakeExporter(t *testing.T) {
	Convey("When using FakeExporter", t, func() {
		event := &eventexporter.Event{Name: "test"}

		fakeExporter := NewFakeExporter()
		err := fakeExporter.Send(event)

		Convey("Then it should save event for debugging", func() {
			So(err, ShouldBeNil)
			So(len(fakeExporter.Events), ShouldEqual, 1)
		})
	})
}
