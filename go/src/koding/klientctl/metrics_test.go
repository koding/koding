package main

import (
	"koding/kites/metrics"
	"testing"
	"time"

	cli "gopkg.in/urfave/cli.v1"
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

func BenchmarkMetricsOverheadAll(b *testing.B) {
	for i := 0; i < b.N; i++ {
		m, err := metrics.New("kd")
		if err != nil {
			b.Fatal(err.Error())
		}
		actionFn := func(*cli.Context) error {
			return nil
		}
		wrappedActionFn := metrics.WrapCLIAction(m.Datadog, actionFn, "", generateTagsForCLI)
		c := &cli.Context{
			Command: cli.Command{
				Name: "full name",
			},
		}
		wrappedActionFn(c)
		m.Close()
	}
}
