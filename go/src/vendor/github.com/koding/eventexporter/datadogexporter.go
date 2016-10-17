package eventexporter

import kodingmetrics "github.com/koding/metrics"

type DatadogExporter struct {
	datadog *kodingmetrics.DogStatsD
}

// NewDatadogExporter initializes DatadogExporter struct
// and NewDatadogExporter implements Exporter interface with Send and Close functions
func NewDatadogExporter(d *kodingmetrics.DogStatsD) *DatadogExporter {
	return &DatadogExporter{datadog: d}
}

func (d *DatadogExporter) Send(m *Event) error {
	eventName, tags := eventSeperator(m)
	_ = d.datadog.Count(eventName, 1, tags, 1)
	return nil
}

func (d *DatadogExporter) Close() error {
	return nil
}
