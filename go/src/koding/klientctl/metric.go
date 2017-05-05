package main

import (
	"koding/kites/metrics"
	"koding/klientctl/ctlcli"
	"time"

	"github.com/codegangsta/cli"
	"github.com/koding/logging"
)

// MetricPushHandler accepts metrics from external sources.
func MetricPushHandler(m *metrics.Metrics, tags []string) ctlcli.ExitingErrCommand {
	return func(c *cli.Context, log logging.Logger, _ string) (int, error) {
		val := c.Float64("count")
		name := "cli_external_" + c.String("name")
		mtype := c.String("type")

		switch mtype {
		case "counter":
			m.Datadog.Count(name, int64(val), tags, 1)
		case "timing":
			m.Datadog.Timing(name, time.Duration(val), tags, 1)
		case "gauge":
			m.Datadog.Gauge(name, val, tags, 1)
		}
		return 0, nil
	}
}
