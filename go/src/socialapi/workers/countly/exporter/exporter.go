package exporter

import (
	"socialapi/config"
	"socialapi/workers/countly/api"
	"socialapi/workers/countly/client"

	"github.com/koding/eventexporter"
	"github.com/koding/logging"
	"github.com/koding/runner"
)

// CountlyExporter exports events to countly..
type CountlyExporter struct {
	client   *client.Client
	log      logging.Logger
	api      *api.CountlyAPI
	disabled bool // if countly integration is disabled.
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
		log:      logger,
		disabled: cfg.Countly.Disabled,
		api:      api.NewCountlyAPI(cfg),
	}
}

// Send publishes the events to countly.
func (c *CountlyExporter) Send(event *eventexporter.Event) error {
	c.log.Debug("got event %+v", event)
	if c.disabled {
		return nil
	}

	slug := getGroupName(event)
	if slug == "" {
		c.log.Debug("skipping event, does not have group %+v", event)
		return nil
	}
	// preserve backward compatibility
	if event.Duration == 0 && event.Count == 0 {
		event.Count = 1
	}

	return c.api.Publish(slug, client.Event{
		Key:          event.Name,
		Count:        int(event.Count),
		Dur:          int(event.Duration.Seconds()),
		Segmentation: event.Properties,
	})

}

// Name returns the name of the exporter.
func (CountlyExporter) Name() string { return "countly" }

// Close closes the exporter.
func (c *CountlyExporter) Close() error {
	return nil
}

func getGroupName(event *eventexporter.Event) string {
	if len(event.Properties) == 0 {
		return ""
	}

	if name, ok := event.Properties["groupName"].(string); ok {
		return name
	}

	if name, ok := event.Properties["group"].(string); ok {
		return name
	}

	return ""
}
