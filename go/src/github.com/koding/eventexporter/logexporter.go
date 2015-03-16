package eventexporter

type LogExporter struct {
	Events []*Event
}

func NewLogExporter() *LogExporter {
	return &LogExporter{Events: []*Event{}}
}

func (l *LogExporter) Send(event *Event) error {
	l.Events = append(l.Events, event)
	return nil
}
