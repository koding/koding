package exporter

import (
	"socialapi/config"
	"socialapi/workers/countly/client"

	"github.com/koding/eventexporter"
	"github.com/koding/logging"
	"github.com/koding/runner"
)

// CountlyExporter exports events to countly..
type CountlyExporter struct {
	client      *client.Client
	log         logging.Logger
	globalOwner string
	groupCache  *groupCache
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
		groupCache:  newGroupCache(),
	}
}

// Send publishes the events to countly.
func (c *CountlyExporter) Send(event *eventexporter.Event) error {
	// fmt.Printf("event %# v", pretty.Formatter(event))

	slug := getGroupName(event)
	if slug == "" {
		c.log.Debug("skipping event, does not have group %+v", event)
		return nil
	}

	if true {
		return nil
	}

	group, err := c.groupCache.BySlug(slug)
	if err != nil {
		return err
	}

	if !group.HasCountly() {
		return nil
	}

	events := []client.Event{client.Event{
		Key:          event.Name,
		Count:        1,
		Segmentation: event.Properties,
	}}
	return c.client.WriteEvent(group.Countly.APPKey, group.Id.Hex(), events)
}

// Close closes the exporter.
func (c *CountlyExporter) Close() error {
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
