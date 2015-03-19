package eventexporter

import (
	analytics "github.com/segmentio/analytics-go"
)

type SegementIOExporter struct {
	Client *analytics.Client
}

func NewSegementIOExporter(key string, size int) *SegementIOExporter {
	client := analytics.New(key)
	client.Size = size

	return &SegementIOExporter{Client: client}
}

func (s *SegementIOExporter) Send(event *Event) error {
	if event.User.Username == "" {
		return ErrorSegmentIOUsernameEmpty
	}

	if event.User.Email == "" {
		return ErrorSegmentIOEmailEmpty
	}

	if event.Name == "" {
		return ErrorSegmentIOEventEmpty
	}

	event = addBody(event)
	event.Properties["email"] = event.User.Email

	return s.Client.Track(&analytics.Track{
		Event:      event.Name,
		UserId:     event.User.Username,
		Properties: event.Properties,
	})
}

func addBody(event *Event) *Event {
	_, ok := event.Properties["body"]
	if ok {
		return event
	}

	if event.Body != nil {
		if event.Properties == nil {
			event.Properties = map[string]interface{}{}
		}

		event.Properties["body"] = event.Body.Content
		event.Properties["bodyType"] = event.Body.Type
	}

	return event
}
