package eventexporter

import (
	"fmt"
	"strings"
)

type MultiExporter []Exporter

// NewMultiExporter inits the exporter services like; segment, datadog etc..
// and implements Exporter interface with Send and Close functions
func NewMultiExporter(e ...Exporter) MultiExporter {
	return MultiExporter(e)
}

// Send publishes the events to multiple upstreams, returns error on first
// occurence
func (m MultiExporter) Send(event *Event) error {
	for _, e := range m {
		if !isWhitelisted(e.Name(), event.WhitelistedUpstreams) {
			continue
		}

		if err := e.Send(event); err != nil {
			return err
		}
	}

	return nil
}

// Name returns the name of the exporter.
func (MultiExporter) Name() string { return "all" }

// Close closes the upstreams.
func (m MultiExporter) Close() error {
	for _, e := range m {
		if err := e.Close(); err != nil {
			return err
		}
	}

	return nil
}

// eventSeperator uses Event struct and seperates eventname and tags.
// while appending tags into array, if tags dont exist in whitelist wont be added to array
// Also empty properties are not added into tags array
func eventSeperator(m *Event) (string, []string) {
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

	return eventName, tags
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

func isWhitelisted(name string, whitelist []string) bool {
	if len(whitelist) == 0 {
		return true
	}

	for _, w := range whitelist {
		if w == name {
			return true
		}
	}

	return false
}
