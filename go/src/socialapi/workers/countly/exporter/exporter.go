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
	client         *client.Client
	log            logging.Logger
	globalOwner    string
	groupDataCache *groupDataCache
	disabled       bool // if countly integration is disabled.
	fixApps        bool // if we should create non existing apps.
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
		log:            logger,
		globalOwner:    cfg.Countly.AppOwner,
		groupDataCache: newGroupCache(),
		disabled:       cfg.Countly.Disabled,
		fixApps:        cfg.Countly.FixApps,
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

	groupData, _ := c.groupDataCache.BySlug(slug)
	appKey := ""
	if groupData != nil {
		appKey, _ = groupData.Payload.GetString("countly.appKey")
	}

	if appKey == "" {
		if !c.fixApps {
			return nil
		}

		cres, err := api.NewCountlyAPI(config.MustGet()).CreateApp(slug)
		if err != nil {
			return err
		}

		appKey = cres.AppID
		groupData, err = c.groupDataCache.Refresh(slug)
		if err != nil {
			return err
		}
	}

	events := []client.Event{{
		Key:          event.Name,
		Count:        1,
		Segmentation: event.Properties,
	}}

	return c.client.WriteEvent(appKey, slug, events)
}

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
