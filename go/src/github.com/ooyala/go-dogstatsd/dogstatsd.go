// Copyright 2013 Ooyala, Inc.

/*
Package dogstatsd provides a Go DogStatsD client. DogStatsD extends StatsD - adding tags and
histograms. Refer to http://docs.datadoghq.com/guides/dogstatsd/ for information about DogStatsD.

Example Usage:
		// Create the client
		c, err := dogstatsd.New("127.0.0.1:8125")
		defer c.Close()
		if err != nil {
			log.Fatal(err)
		}
		// Prefix every metric with the app name
		c.Namespace = "flubber."
		// Send the EC2 availability zone as a tag with every metric
		append(c.Tags, "us-east-1a")
		err = c.Gauge("request.duration", 1.2, nil, 1)

		// Post info to datadog event stream
		err = c.Info("cookie alert", "Cookies up for grabs in the kitchen!", nil)

dogstatsd is based on go-statsd-client.
*/
package dogstatsd

import (
	"bytes"
	"fmt"
	"math/rand"
	"net"
	"strings"
	"time"
	"unicode/utf8"
)

type Client struct {
	conn net.Conn
	// Namespace to prepend to all statsd calls
	Namespace string
	// Global tags to be added to every statsd call
	Tags []string
}

// New returns a pointer to a new Client and an error.
// addr must have the format "hostname:port"
func New(addr string) (*Client, error) {
	conn, err := net.Dial("udp", addr)
	if err != nil {
		return nil, err
	}
	client := &Client{conn: conn}
	return client, nil
}

// Close closes the connection to the DogStatsD agent
func (c *Client) Close() error {
	return c.conn.Close()
}

// send handles sampling and sends the message over UDP. It also adds global namespace prefixes and tags.
func (c *Client) send(name string, value string, tags []string, rate float64) error {
	if rate < 1 {
		if rand.Float64() < rate {
			value = fmt.Sprintf("%s|@%f", value, rate)
		} else {
			return nil
		}
	}

	if c.Namespace != "" {
		name = fmt.Sprintf("%s%s", c.Namespace, name)
	}

	tags = append(c.Tags, tags...)
	if len(tags) > 0 {
		value = fmt.Sprintf("%s|#%s", value, strings.Join(tags, ","))
	}

	data := fmt.Sprintf("%s:%s", name, value)
	_, err := c.conn.Write([]byte(data))
	return err
}

// AlertType represents the supported alert_types of Datadog events.
type AlertType string

// A Datadog event priority (e.g. 'normal' or 'low')
type PriorityType string

const (
	Info          AlertType    = "info"
	Success       AlertType    = "success"
	Warning       AlertType    = "warning"
	Error         AlertType    = "error"
	Normal        PriorityType = "normal"
	Low           PriorityType = "low"
	maxEventBytes              = 8192
)

// Detailed options for Event generation
type EventOpts struct {
	DateHappened                         time.Time
	Priority                             PriorityType
	Host, AggregationKey, SourceTypeName string
	Tags                                 []string
	AlertType                            AlertType
}

func newDefaultEventOpts(alertType AlertType, tags []string, namespace string) *EventOpts {
	eo := EventOpts{
		AlertType: alertType,
		Tags:      tags,
	}
	// Use the given client namespace as the source type name, if given
	if namespace != "" {
		source := namespace
		if period := strings.IndexByte(source, '.'); period > -1 {
			source = source[:period]
		}
		eo.SourceTypeName = source
	}
	return &eo
}

// Event posts to the Datadog event stream.
// Four event types are supported: info, success, warning, error.
// If client Namespace is set it is used as the Event source.
func (c *Client) Info(title string, text string, tags []string) error {
	return c.Event(title, text, newDefaultEventOpts(Info, tags, c.Namespace))
}
func (c *Client) Success(title string, text string, tags []string) error {
	return c.Event(title, text, newDefaultEventOpts(Success, tags, c.Namespace))
}
func (c *Client) Warning(title string, text string, tags []string) error {
	return c.Event(title, text, newDefaultEventOpts(Warning, tags, c.Namespace))
}
func (c *Client) Error(title string, text string, tags []string) error {
	return c.Event(title, text, newDefaultEventOpts(Error, tags, c.Namespace))
}
func (c *Client) Event(title string, text string, eo *EventOpts) error {
	var b bytes.Buffer
	fmt.Fprintf(&b, "_e{%d,%d}:%s|%s|t:%s", utf8.RuneCountInString(title),
		utf8.RuneCountInString(text), title, text, eo.AlertType)

	if eo.SourceTypeName != "" {
		fmt.Fprintf(&b, "|s:%s", eo.SourceTypeName)
	}
	if !eo.DateHappened.IsZero() {
		fmt.Fprintf(&b, "|d:%d", eo.DateHappened.Unix())
	}
	if eo.Priority != "" {
		fmt.Fprintf(&b, "|p:%s", eo.Priority)
	}
	if eo.Host != "" {
		fmt.Fprintf(&b, "|h:%s", eo.Host)
	}
	if eo.AggregationKey != "" {
		fmt.Fprintf(&b, "|k:%s", eo.AggregationKey)
	}
	tags := append(c.Tags, eo.Tags...)
	format := "|#%s"
	for _, t := range tags {
		fmt.Fprintf(&b, format, t)
		format = ",%s"
	}

	bytes := b.Bytes()
	if len(bytes) > maxEventBytes {
		return fmt.Errorf("Event '%s' payload is too big (more that 8KB), event discarded", title)
	}
	_, err := c.conn.Write(bytes)
	return err
}

// Gauges measure the value of a metric at a particular time
func (c *Client) Gauge(name string, value float64, tags []string, rate float64) error {
	stat := fmt.Sprintf("%f|g", value)
	return c.send(name, stat, tags, rate)
}

// Counters track how many times something happened per second
func (c *Client) Count(name string, value int64, tags []string, rate float64) error {
	stat := fmt.Sprintf("%d|c", value)
	return c.send(name, stat, tags, rate)
}

// Histograms track the statistical distribution of a set of values
func (c *Client) Histogram(name string, value float64, tags []string, rate float64) error {
	stat := fmt.Sprintf("%f|h", value)
	return c.send(name, stat, tags, rate)
}

// Sets count the number of unique elements in a group
func (c *Client) Set(name string, value string, tags []string, rate float64) error {
	stat := fmt.Sprintf("%s|s", value)
	return c.send(name, stat, tags, rate)
}
