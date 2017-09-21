package cli

import (
	"strings"
	"testing"
	"time"

	"koding/kites/metrics"
)

func BenchmarkMetricsOverheadTags(b *testing.B) {
	for i := 0; i < b.N; i++ {
		_ = generateTagsForCLI("full string")
	}
}

func BenchmarkMetricsOverheadSend(b *testing.B) {
	m, err := metrics.New("kd")
	if err != nil {
		b.Fatal(err.Error())
	}

	defer m.Close()
	tags := generateTagsForCLI("full string")
	for i := 0; i < b.N; i++ {
		m.Datadog.Count("metricName_call_count", 1, tags, 1)
		m.Datadog.Timing("metricName_timing", time.Second, tags, 1)
	}
}

func generateTagsForCLI(full string) []string {
	return append(
		CommandPathTags(strings.Split(full, " ")...),
		ApplicationInfoTags()...,
	)
}
