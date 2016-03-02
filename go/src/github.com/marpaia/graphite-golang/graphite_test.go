package graphite

import (
	"net"
	"testing"
)

// Change these to be your own graphite server if you so please
var graphiteHost = "carbon.hostedgraphite.com"
var graphitePort = 2003

func TestNewGraphite(t *testing.T) {
	gh, err := NewGraphite(graphiteHost, graphitePort)
	if err != nil {
		t.Error(err)
	}

	if _, ok := gh.conn.(*net.TCPConn); !ok {
		t.Error("GraphiteHost.conn is not a TCP connection")
	}
}

func TestNewGraphiteWithMetricPrefix(t *testing.T) {
	prefix := "test"
	gh, err := NewGraphiteWithMetricPrefix(graphiteHost, graphitePort, prefix)
	if err != nil {
		t.Error(err)
	}

	if _, ok := gh.conn.(*net.TCPConn); !ok {
		t.Error("GraphiteHost.conn is not a TCP connection")
	}
}

func TestNewGraphiteUDP(t *testing.T) {
	gh, err := NewGraphiteUDP(graphiteHost, graphitePort)
	if err != nil {
		t.Error(err)
	}

	if _, ok := gh.conn.(*net.UDPConn); !ok {
		t.Error("GraphiteHost.conn is not a UDP connection")
	}
}

// Uncomment the following method to test sending an actual metric to graphite
//
//func TestSendMetric(t *testing.T) {
//	gh, err := NewGraphite(graphiteHost, graphitePort)
//	if err != nil {
//		t.Error(err)
//	}
//	err = gh.SimpleSend("stats.test.metric11", "1")
//	if err != nil {
//		t.Error(err)
//	}
//}
