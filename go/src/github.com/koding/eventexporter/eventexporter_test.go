package eventexporter_test

import (
	"testing"

	"github.com/koding/eventexporter"
	. "github.com/smartystreets/goconvey/convey"
)

type FakeExporter struct {
	Events []*eventexporter.Event
}

func NewFakeExporter() *FakeExporter {
	return &FakeExporter{Events: []*eventexporter.Event{}}
}

func (l *FakeExporter) Send(event *eventexporter.Event) error {
	l.Events = append(l.Events, event)
	return nil
}

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
