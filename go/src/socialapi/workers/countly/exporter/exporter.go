package exporter

import (
	"fmt"
	"socialapi/config"
	"socialapi/workers/countly/client"

	"github.com/koding/eventexporter"
	"github.com/koding/logging"
	"github.com/koding/runner"
	"github.com/kr/pretty"
)

// CountlyExporter exports events to countly..
type CountlyExporter struct {
	client      *client.Client
	log         logging.Logger
	globalOwner string
}

// NewCountlyExporter creates exporter for countly.
func NewCountlyExporter(cfg *config.Config) *CountlyExporter {
	logger := runner.MustGetLogger().New("countly-exporter")
	return &CountlyExporter{
		client: client.New(
			cfg.Countly.APIKey,
			client.SetBaseURL(cfg.Countly.Host),
			client.SetLogger(logger),
		),
		log:         logger,
		globalOwner: cfg.Countly.AppOwner,
	}
}

// Send publishes the events to countly.
func (s *CountlyExporter) Send(event *eventexporter.Event) error {
	fmt.Printf("event %# v", pretty.Formatter(event))

	slug := getGroupName(event)
	if slug == "" {
		s.log.Debug("skipping event, does not have group %+v", event)
		return nil
	}

	return nil
}

// Close closes the exporter.
func (s *CountlyExporter) Close() error {
	return nil
}

func getGroupName(event *eventexporter.Event) string {
	if len(event.Properties) == 0 {
		return ""
	}

	if name := event.Properties["groupName"]; name != "" {
		return name.(string)
	}

	if name := event.Properties["group"]; name != "" {
		return name.(string)
	}

	return ""
}
