package metrics

import (
	"context"
	"testing"
	"time"
)

func TestMetricsProcess(t *testing.T) {
	withMetrics(t, func(m *Metrics) {
		_ = m.Datadog.Count("name", 1, nil, 1)
		_ = m.Datadog.Count("name", 1, nil, 1)

		want := 2
		got := 0
		err := m.Process(func(res [][]byte) error {
			got = len(res)
			return nil
		})
		if err != nil {
			t.Fatalf("m.Process() error = %v, want %v", err, nil)
		}

		if got != want {
			t.Fatalf("got = %v, want %v", got, want)
		}
	})
}

func TestMetricsProcessContextDeadline(t *testing.T) {
	withMetrics(t, func(m *Metrics) {
		_ = m.Datadog.Count("name", 1, nil, 1)
		_ = m.Datadog.Count("name", 1, nil, 1)

		want := 1
		got := 0
		deadline := time.Millisecond * 10
		ctx, cancel := context.WithTimeout(context.Background(), deadline)
		defer cancel()
		err := m.ProcessContext(ctx, 1, func(res [][]byte) error {
			got = got + len(res)
			time.Sleep(deadline)
			return nil
		})
		if err != context.DeadlineExceeded {
			t.Fatalf("m.ProcessContext() error = %v, want %v", err, context.DeadlineExceeded)
		}

		if got != want {
			t.Fatalf("got = %v, want %v", got, want)
		}
	})
}

func TestMetricsProcessContext(t *testing.T) {
	withMetrics(t, func(m *Metrics) {
		_ = m.Datadog.Count("name", 1, nil, 1)
		_ = m.Datadog.Count("name", 1, nil, 1)

		want := 2
		got := 0
		deadline := time.Millisecond * 10
		ctx, cancel := context.WithTimeout(context.Background(), deadline)
		defer cancel()
		err := m.ProcessContext(ctx, 10, func(res [][]byte) error {
			got = got + len(res)
			time.Sleep(deadline)
			return nil
		})
		if err != nil {
			t.Fatalf("m.ProcessContext() error = %v, want %v", err, nil)
		}

		if got != want {
			t.Fatalf("got = %v, want %v", got, want)
		}
	})
}
