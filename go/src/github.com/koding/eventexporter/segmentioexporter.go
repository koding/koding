package eventexporter

import analytics "github.com/segmentio/analytics-go"

type SegementIOExporter struct {
	Client *analytics.Client
}

func NewSegementIOExporter(endpoint, key string, size int) *SegementIOExporter {
	client := analytics.New(key)
	if endpoint != "" {
		client.Endpoint = endpoint
	}

	client.Size = size

	return &SegementIOExporter{Client: client}
}

func (s *SegementIOExporter) Send(event *Event) error {
	event = addBody(event)

	if event.User.Username == "" {
		return ErrorUsernameEmpty
	}

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
