package eventexporter

import (
	"fmt"
	"strings"

	kodingmetrics "github.com/koding/metrics"
)

type DatadogExporter struct {
	datadog *kodingmetrics.DogStatsD
}

// NewDatadogExporter initializes DatadogExporter struct
// and NewDatadogExporter implements Exporter interface with Send and Close functions
func NewDatadogExporter(d *kodingmetrics.DogStatsD) *DatadogExporter {
	return &DatadogExporter{datadog: d}
}

func (d *DatadogExporter) Send(m *Event) error {
	eventName := strings.Replace(m.Name, " ", "_", -1)

	tags := make([]string, 0)
	if m.User.Email != "" {
		tags = append(tags, fmt.Sprintf("email:%s", m.User.Email))
	}

	if m.User.Username != "" {
		tags = append(tags, fmt.Sprintf("username:%s", m.User.Username))
	}

	for key, val := range m.Properties {
		value, ok := val.(string)
		if !ok {
			continue
		}

		if isAllowed(key) && value != "" {
			tags = append(tags, fmt.Sprintf("%s:%s", clean(key), clean(val.(string))))
		}
	}

	return d.datadog.Count(eventName, 1, tags, 1)
}

func (d *DatadogExporter) Close() error {
	return nil
}

func clean(s string) string {
	return strings.Replace(s, " ", "_", -1)
}

func isAllowed(ß string) bool {
	whitelist := []string{
		"host",
		"groupName",
		"email",
		"inviter",
		"subject",
		"env",
		"category",
		"label",
		"firstName",
		"invitesCount",
		"group",
	}

	for _, val := range whitelist {
		if ß == val {
			return true
		}
	}

	return false
}
