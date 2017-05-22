package eventexporter

type FakeExporter struct {
	Events []*Event
}

func NewFakeExporter() *FakeExporter {
	return &FakeExporter{Events: []*Event{}}
}

func (l *FakeExporter) Send(event *Event) error {
	l.Events = append(l.Events, event)
	return nil
}

// Name returns the name of the exporter.
func (FakeExporter) Name() string { return "fake" }

func (l *FakeExporter) Close() error {
	return nil
}
