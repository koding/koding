package eventexportertest

import (
	"github.com/koding/eventexporter"
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
