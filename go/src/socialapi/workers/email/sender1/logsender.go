package sender

type LogSender struct {
	Events []*Event
}

func NewLogSender() *LogSender {
	return &LogSender{Events: []*Event{}}
}

func (l *LogSender) Send(event *Event) error {
	l.Events = append(l.Events, event)
	return nil
}
