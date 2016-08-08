// Copyright 2013 Ooyala, Inc.

package dogstatsd

import (
	"bytes"
	"fmt"
	"net"
	"reflect"
	"testing"
	"time"
)

var dogstatsdTests = []struct {
	GlobalNamespace string
	GlobalTags      []string
	Method          string
	Metric          string
	Value           interface{}
	Tags            []string
	Rate            float64
	Expected        string
}{
	{"", nil, "Gauge", "test.gauge", 1.0, nil, 1.0, "test.gauge:1.000000|g"},
	{"", nil, "Gauge", "test.gauge", 1.0, nil, 0.999999, "test.gauge:1.000000|g|@0.999999"},
	{"", nil, "Gauge", "test.gauge", 1.0, []string{"tagA"}, 1.0, "test.gauge:1.000000|g|#tagA"},
	{"", nil, "Gauge", "test.gauge", 1.0, []string{"tagA", "tagB"}, 1.0, "test.gauge:1.000000|g|#tagA,tagB"},
	{"", nil, "Gauge", "test.gauge", 1.0, []string{"tagA"}, 0.999999, "test.gauge:1.000000|g|@0.999999|#tagA"},
	{"", nil, "Count", "test.count", int64(1), []string{"tagA"}, 1.0, "test.count:1|c|#tagA"},
	{"", nil, "Count", "test.count", int64(-1), []string{"tagA"}, 1.0, "test.count:-1|c|#tagA"},
	{"", nil, "Histogram", "test.histogram", 2.3, []string{"tagA"}, 1.0, "test.histogram:2.300000|h|#tagA"},
	{"", nil, "Set", "test.set", "uuid", []string{"tagA"}, 1.0, "test.set:uuid|s|#tagA"},
	{"flubber.", nil, "Set", "test.set", "uuid", []string{"tagA"}, 1.0, "flubber.test.set:uuid|s|#tagA"},
	{"", []string{"tagC"}, "Set", "test.set", "uuid", []string{"tagA"}, 1.0, "test.set:uuid|s|#tagC,tagA"},
}

func TestClient(t *testing.T) {
	addr := "localhost:1201"
	server := newServer(t, addr)
	defer server.Close()
	client := newClient(t, addr)
	defer client.Close()

	for _, tt := range dogstatsdTests {
		client.Namespace = tt.GlobalNamespace
		client.Tags = tt.GlobalTags
		method := reflect.ValueOf(client).MethodByName(tt.Method)
		e := method.Call([]reflect.Value{
			reflect.ValueOf(tt.Metric),
			reflect.ValueOf(tt.Value),
			reflect.ValueOf(tt.Tags),
			reflect.ValueOf(tt.Rate)})[0]
		errInter := e.Interface()
		if errInter != nil {
			t.Fatal(errInter.(error))
		}

		message := serverRead(t, server)
		if message != tt.Expected {
			t.Errorf("Expected: %s. Actual: %s", tt.Expected, message)
		}
	}

}

type eventTest struct {
	logEvent func(*Client) error
	expected string
}

var eventTests = []eventTest{
	eventTest{
		logEvent: func(c *Client) error { return c.Warning("title", "text", []string{"tag1", "tag2"}) },
		expected: "_e{5,4}:title|text|t:warning|s:flubber|#tag1,tag2",
	},
	eventTest{
		logEvent: func(c *Client) error { return c.Error("Error!", "some error", []string{"tag3"}) },
		expected: "_e{6,10}:Error!|some error|t:error|s:flubber|#tag3",
	},
	eventTest{
		logEvent: func(c *Client) error { return c.Info("FYI", "note", []string{}) },
		expected: "_e{3,4}:FYI|note|t:info|s:flubber",
	},
	eventTest{
		logEvent: func(c *Client) error { return c.Success("Great News", "hurray", []string{"foo", "bar", "baz"}) },
		expected: "_e{10,6}:Great News|hurray|t:success|s:flubber|#foo,bar,baz",
	},
	eventTest{
		logEvent: func(c *Client) error { return c.Info("Unicode", "世界", []string{}) },
		// Expect character, not byte lengths
		expected: "_e{7,2}:Unicode|世界|t:info|s:flubber",
	},
	eventTest{
		logEvent: func(c *Client) error {
			eo := EventOpts{
				DateHappened:   time.Date(2014, time.September, 18, 22, 56, 0, 0, time.UTC),
				Priority:       Normal,
				Host:           "node.example.com",
				AggregationKey: "foo",
				SourceTypeName: "bar",
				AlertType:      Success,
			}
			return c.Event("custom title", "custom body", &eo)
		},
		expected: "_e{12,11}:custom title|custom body|t:success|s:bar|d:1411080960|p:normal|h:node.example.com|k:foo",
	},
}

func TestEvent(t *testing.T) {
	addr := "localhost:1201"
	server := newServer(t, addr)
	defer server.Close()
	client := newClient(t, addr)
	client.Namespace = "flubber."

	for _, tt := range eventTests {
		if err := tt.logEvent(client); err != nil {
			t.Fatal(err)
		}
		message := serverRead(t, server)
		if message != tt.expected {
			t.Errorf("Expected: %s. Actual: %s", tt.expected, message)
		}
	}

	var b bytes.Buffer
	for i := 0; i < maxEventBytes+1; i++ {
		fmt.Fprintf(&b, "a")
	}
	err := client.Error("too long", b.String(), []string{})
	if err == nil || err.Error() != "Event 'too long' payload is too big (more that 8KB), event discarded" {
		t.Errorf("Expected error due to exceeded event byte length")
	}
}

func serverRead(t *testing.T, server *net.UDPConn) string {
	bytes := make([]byte, 1024)
	n, _, err := server.ReadFrom(bytes)
	if err != nil {
		t.Fatal(err)
	}
	return string(bytes[:n])
}

func newClient(t *testing.T, addr string) *Client {
	client, err := New(addr)
	if err != nil {
		t.Fatal(err)
	}
	return client
}

func newServer(t *testing.T, addr string) *net.UDPConn {
	udpAddr, err := net.ResolveUDPAddr("udp", addr)
	if err != nil {
		t.Fatal(err)
	}

	server, err := net.ListenUDP("udp", udpAddr)
	if err != nil {
		t.Fatal(err)
	}
	return server
}
