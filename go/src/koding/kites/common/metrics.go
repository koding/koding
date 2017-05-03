package common

import (
	"fmt"
	"net/http"
	"strings"
	"time"

	dogstatsd "github.com/DataDog/datadog-go/statsd"
	"github.com/koding/kite"
)

// MustInitMetrics inits dogstats client.
func MustInitMetrics(name string) *dogstatsd.Client {
	stats, err := dogstatsd.New("127.0.0.1:8125")
	if err != nil {
		panic(err)
	}

	stats.Namespace = name + "_"
	return stats
}

// WrapKiteHandler wraps the kite handlers adds metrics middlewares.
func WrapKiteHandler(dd *dogstatsd.Client, metricName string, handler kite.HandlerFunc) kite.HandlerFunc {
	return func(r *kite.Request) (interface{}, error) {
		var tags []string

		start := time.Now()

		resp, err := handler.ServeKite(r)
		dur := time.Since(start)

		tags = AppendTag(tags, "success", err == nil)

		dd.Count(metricName+"_call_count", 1, tags, 1)
		dd.Timing(metricName+"_timing", dur, tags, 1)

		return resp, err
	}
}

// WrapHTTPHandler wraps the http handlers adds metrics middlewares.
func WrapHTTPHandler(dd *dogstatsd.Client, metricName string, handler http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		var tags []string

		start := time.Now()

		handler(w, r)
		dur := time.Since(start)

		dd.Count(metricName+"_call_count", 1, tags, 1)
		dd.Timing(metricName+"_timing", dur, tags, 1)
	}
}

// AppendTag appends DD tags with formatting.
func AppendTag(tags []string, key string, val interface{}) []string {
	// http://docs.datadoghq.com/guides/dogstatsd/#datagram-format
	tag := fmt.Sprintf("%s:%v", key, val)
	tag = strings.Replace(tag, " ", "_", -1)
	return append(tags, tag)
}
