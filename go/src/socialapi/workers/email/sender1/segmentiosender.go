package sender

import analytics "github.com/segmentio/analytics-go"

var (
	// TODO: remove this; this should be sent by worker calling this
	DefaultSegmentIOKey = "kb2hfdgf20"
)

type SegementIOSender struct {
	Client *analytics.Client
}

func NewSegementIOSender(endpoint, key string) *SegementIOSender {
	client := analytics.New(key)
	if endpoint != "" {
		client.Endpoint = endpoint
	}

	return &SegementIOSender{Client: client}
}

func (s *SegementIOSender) Send(event *Event) error {
	_, ok := event.Properties["body"]
	if !ok {
		if event.Body != nil {
			event.Properties["body"] = event.Body.Content
			event.Properties["bodyType"] = event.Body.Type
		}
	}

	err := s.Client.Track(&analytics.Track{
		Event:      event.Name,
		UserId:     event.User.Username,
		Properties: event.Properties,
	})

	return err
}
