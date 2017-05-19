package metrics

import (
	"io/ioutil"
	"os"
	"testing"
	"time"
)

func TestBoltRead(t *testing.T) {
	withMetrics(t, func(m *Metrics) {
		testStorageRead(t, m)
	})
}

func TestBoltForEachN(t *testing.T) {
	withMetrics(t, func(m *Metrics) {
		testStorageForEachN(t, m)
	})
}

func withMetrics(t *testing.T, f func(*Metrics)) {
	tmpfile, err := ioutil.TempFile("", "db.bolt")
	if err != nil {
		t.Fatalf("ioutil.TempFile()) error = %v, want %v", err, nil)
	}

	defer os.Remove(tmpfile.Name())

	path := tmpfile.Name()
	m, err := NewWithPath(path, "app")
	if err != nil {
		t.Fatalf("NewBoltConn() error = %v, want %v", err, nil)
	}
	defer m.Close()

	f(m)
}

func testStorageRead(t *testing.T, m *Metrics) {
	err := m.Datadog.Gauge("name_gauge", 1, []string{"GaugeTag"}, 1)
	if err != nil {
		t.Fatalf("m.Datadog.Gauge() error = %v, want %v", err, nil)
	}

	if err = m.Datadog.Count("name_count", 1, []string{"CountTag"}, 1); err != nil {
		t.Fatalf("m.Datadog.Count() error = %v, want %v", err, nil)
	}

	if err = m.Datadog.Histogram("name_histogram", 1, []string{"HistogramTag"}, 1); err != nil {
		t.Fatalf("m.Datadog.Histogram() error = %v, want %v", err, nil)
	}

	if err = m.Datadog.Set("name_set", "1", []string{"SetTag"}, 1); err != nil {
		t.Fatalf("m.Datadog.Set() error = %v, want %v", err, nil)
	}

	if err = m.Datadog.Timing("name_timing", time.Second, []string{"TimingTag"}, 1); err != nil {
		t.Fatalf("m.Datadog.Timing() error = %v, want %v", err, nil)
	}

	readCount := 2

	want := readCount
	n := readCount
	checkConsumeN(t, m.storage, want, n)

	want = readCount
	n = readCount
	checkConsumeN(t, m.storage, want, n)

	want = 1
	n = readCount
	checkConsumeN(t, m.storage, want, n)

	if err := m.storage.Close(); err != nil {
		t.Fatalf("m.storage.Close() error = %v, want %v", err, nil)
	}
}

func testStorageForEachN(t *testing.T, m *Metrics) {
	// try < 0
	want := 0
	n := -1
	checkConsumeN(t, m.storage, want, n)

	// try 0
	want = 0
	n = want
	checkConsumeN(t, m.storage, want, n)

	_ = m.Datadog.Count("name", 1, nil, 1)

	// try > 0
	want = 1
	n = want
	checkConsumeN(t, m.storage, want, n)

	_ = m.Datadog.Count("name", 1, nil, 1)
	_ = m.Datadog.Count("name", 1, nil, 1)

	// try < 0 for consuming
	want = 2
	n = -1
	checkConsumeN(t, m.storage, want, n)
}

func checkConsumeN(t *testing.T, b Storage, want, n int) {
	got, err := b.ConsumeN(n, func(res [][]byte) error {
		return nil
	})

	if err != nil {
		t.Fatalf("m.storage.ForEachN() error = %v, want %v", err, nil)
	}

	if got != want {
		t.Fatalf("got = %v, want %v", got, want)
	}
}
