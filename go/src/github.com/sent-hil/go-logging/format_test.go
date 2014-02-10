// Copyright 2013, Örjan Persson. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package logging

import (
	"bytes"
	"testing"
)

func TestFormat(t *testing.T) {
	backend := InitForTesting(DEBUG)

	f, err := NewStringFormatter("%{time:2006-01-02T15:04:05} %{level:.1s} %{id:04d} %{module} %{message}")
	if err != nil {
		t.Fatalf("failed to set format: %s", err)
	}
	SetFormatter(f)

	log := MustGetLogger("module")
	log.Debug("hello")

	line := MemoryRecordN(backend, 0).Formatted()
	if "1970-01-01T00:00:00 D 0001 module hello" != line {
		t.Errorf("Unexpected format: %s", line)
	}
}

func BenchmarkStringFormatter(b *testing.B) {
	fmt := "%{time:2006-01-02T15:04:05} %{level:.1s} %{id:04d} %{module} %{message}"
	f := MustStringFormatter(fmt)

	backend := InitForTesting(DEBUG)
	buf := &bytes.Buffer{}
	log := MustGetLogger("module")
	log.Debug("")
	record := MemoryRecordN(backend, 0)

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		if err := f.Format(record, buf); err != nil {
			b.Fatal(err)
			buf.Truncate(0)
		}
	}
}
