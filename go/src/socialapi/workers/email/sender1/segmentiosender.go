package sender

import analytics "github.com/segmentio/analytics-go"

var (
	// TODO: remove this; this should be sent by worker calling this
	DefaultSegmentIOKey = "kb2hfdgf20"
)

type SegementIOSender struct {
	Client *analytics.Client
}

func NewSegementIOSender(endpoint, key string, size int) *SegementIOSender {
	client := analytics.New(key)
	if endpoint != "" {
		client.Endpoint = endpoint
	}

	client.Size = size

	return &SegementIOSender{Client: client}
}

func (s *SegementIOSender) Send(event *Event) error {
	event = addBody(event)

	err := s.Client.Track(&analytics.Track{
		Event:      event.Name,
		UserId:     event.User.Username,
		Properties: event.Properties,
	})

	return err
}

func addBody(event *Event) *Event {
	_, ok := event.Properties["body"]
	if ok {
		return event
	}

	if event.Body != nil {
		event.Properties["body"] = event.Body.Content
		event.Properties["bodyType"] = event.Body.Type
	}

	return event
}
