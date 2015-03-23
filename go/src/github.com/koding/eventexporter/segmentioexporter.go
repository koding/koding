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

func buildTrack(event *Event) (*analytics.Track, error) {
	if event.User.Username == "" {
		return nil, ErrSegmentIOUsernameEmpty
	}

	if event.User.Email == "" {
		return nil, ErrSegmentIOEmailEmpty
	}

	if event.Name == "" {
		return nil, ErrSegmentIOEventEmpty
	}

	event.Properties["email"] = event.User.Email
	event.Properties["currentDate"] = time.Now().UTC().Format(DateLayout)

	return &analytics.Track{
		Event:      event.Name,
		UserId:     event.User.Username,
		Properties: event.Properties,
	}, nil
}
