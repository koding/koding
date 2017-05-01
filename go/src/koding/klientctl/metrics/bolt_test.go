package metrics

import (
	"io/ioutil"
	"os"
	"testing"
	"time"
)

func TestBoltRead(t *testing.T) {
	tmpfile, err := ioutil.TempFile("", "db.bolt")
	if err != nil {
		t.Fatalf("ioutil.TempFile()) error = %v, want %v", err, nil)
	}

	defer os.Remove(tmpfile.Name())

	path, bucket := tmpfile.Name(), "bucket"
	bdb, err := NewBoltConn(path, bucket)
	if err != nil {
		t.Fatalf("NewBoltConn() error = %v, want %v", err, nil)
	}

	cd, err := NewDataDogClient(bdb)
	if err != nil {
		t.Fatalf("NewBoltConn() error = %v, want %v", err, nil)
	}

	if err = cd.Gauge("name_gauge", 1, []string{"GaugeTag"}, 1); err != nil {
		t.Fatalf("cd.Gauge() error = %v, want %v", err, nil)
	}

	if err = cd.Count("name_count", 1, []string{"CountTag"}, 1); err != nil {
		t.Fatalf("cd.Count() error = %v, want %v", err, nil)
	}

	if err = cd.Histogram("name_histogram", 1, []string{"HistogramTag"}, 1); err != nil {
		t.Fatalf("cd.Histogram() error = %v, want %v", err, nil)
	}

	if err = cd.Set("name_set", "1", []string{"SetTag"}, 1); err != nil {
		t.Fatalf("cd.Set() error = %v, want %v", err, nil)
	}

	if err = cd.Timing("name_timing", time.Second, []string{"TimingTag"}, 1); err != nil {
		t.Fatalf("cd.Timing() error = %v, want %v", err, nil)
	}

	readCount := 2
	res, err := bdb.ReadN(readCount)
	if err != nil {
		t.Fatalf(" bdb.db.Update() error = %v, want %v", err, nil)
	}

	if got := len(res); got != readCount {
		t.Fatalf("readCount = %v, want %v", got, readCount)
	}

	res, err = bdb.ReadN(readCount)
	if err != nil {
		t.Fatalf(" bdb.db.Update() error = %v, want %v", err, nil)
	}

	if got := len(res); got != readCount {
		t.Fatalf("readCount = %v, want %v", got, readCount)
	}

	res, err = bdb.ReadN(readCount)
	if err != nil {
		t.Fatalf(" bdb.db.Update() error = %v, want %v", err, nil)
	}

	if got := len(res); got != 1 { // we wrote 5 items.
		t.Fatalf("readCount = %v, want %v", got, 1)
	}

	if err := bdb.Close(); err != nil {
		t.Fatalf("bdb.Close() error = %v, want %v", err, nil)
	}
}
