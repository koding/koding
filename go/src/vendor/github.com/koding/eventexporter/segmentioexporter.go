package eventexporter

import (
	"time"

	analytics "github.com/segmentio/analytics-go"
)

var DateLayout = "Jan 2, 2006"

type SegmentIOExporter struct {
	Client *analytics.Client
}

func NewSegmentIOExporter(key string, size int) *SegmentIOExporter {
	client := analytics.New(key) // access token to authorize requests
	client.Size = size           // size of queue before flushing to api

	return &SegmentIOExporter{Client: client}
}

func (s *SegmentIOExporter) Send(event *Event) error {
	trackEvent, err := buildTrack(event)
	if err != nil {
		return err
	}

	return s.Client.Track(trackEvent)
}

func (s *SegmentIOExporter) Close() error {
	return s.Client.Close()
}

func buildTrack(event *Event) (*analytics.Track, error) {
	if event.User == nil {
		return nil, ErrSegmentIOUsernameEmpty
	}

	if event.User.Username == "" {
		return nil, ErrSegmentIOUsernameEmpty
	}

	if event.Name == "" {
		return nil, ErrSegmentIOEventEmpty
	}

	event = addBody(event)

	return &analytics.Track{
		Event:      event.Name,
		UserId:     event.User.Username,
		Properties: event.Properties,
		Context:    event.Context,
	}, nil
}

// Name returns the name of the exporter.
func (SegmentIOExporter) Name() string { return "segment" }

func addBody(event *Event) *Event {
	if event.Properties == nil {
		event.Properties = map[string]interface{}{}
	}

	if event.Properties["email"] == nil {
		event.Properties["email"] = event.User.Email
	}

	event.Properties["currentDate"] = time.Now().UTC().Format(DateLayout)

	if event.Body != nil {
		event.Properties["body"] = event.Body.Content
		event.Properties["bodyType"] = event.Body.Type
	}

	return event
}
