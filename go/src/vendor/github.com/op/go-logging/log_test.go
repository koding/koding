// Copyright 2013, Örjan Persson. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package logging

import (
	"bytes"
	"log"
	"strings"
	"testing"
)

func TestLogCalldepth(t *testing.T) {
	buf := &bytes.Buffer{}
	SetBackend(NewLogBackend(buf, "", log.Lshortfile))

	log := MustGetLogger("test")
	log.Info("test filename")

	// Verify that the correct filename is registered
	if !strings.HasPrefix(buf.String(), "log_test.go:") {
		t.Errorf("incorrect filename: %s", buf.String())
	}
}

func BenchmarkLogMemoryBackendIgnored(b *testing.B) {
	b.StopTimer()
	backend := SetBackend(NewMemoryBackend(1024))
	backend.SetLevel(INFO, "")
	RunLogBenchmark(b)
}

func BenchmarkLogMemoryBackend(b *testing.B) {
	b.StopTimer()
	backend := SetBackend(NewMemoryBackend(1024))
	backend.SetLevel(DEBUG, "")
	RunLogBenchmark(b)
}

func BenchmarkLogChannelMemoryBackend(b *testing.B) {
	b.StopTimer()
	channelBackend := NewChannelMemoryBackend(1024)
	backend := SetBackend(channelBackend)
	backend.SetLevel(DEBUG, "")
	RunLogBenchmark(b)
	channelBackend.Flush()
}

func BenchmarkLogLogBackend(b *testing.B) {
	b.StopTimer()
	backend := SetBackend(NewLogBackend(&bytes.Buffer{}, "", 0))
	backend.SetLevel(DEBUG, "")
	RunLogBenchmark(b)
}

func BenchmarkLogLogBackendColor(b *testing.B) {
	b.StopTimer()
	colorizer := NewLogBackend(&bytes.Buffer{}, "", 0)
	colorizer.Color = true
	backend := SetBackend(colorizer)
	backend.SetLevel(DEBUG, "")
	RunLogBenchmark(b)
}

func BenchmarkLogLogBackendStdFlags(b *testing.B) {
	b.StopTimer()
	backend := SetBackend(NewLogBackend(&bytes.Buffer{}, "", log.LstdFlags))
	backend.SetLevel(DEBUG, "")
	RunLogBenchmark(b)
}

func BenchmarkLogLogBackendLongFileFlag(b *testing.B) {
	b.StopTimer()
	backend := SetBackend(NewLogBackend(&bytes.Buffer{}, "", log.Llongfile))
	backend.SetLevel(DEBUG, "")
	RunLogBenchmark(b)
}

func RunLogBenchmark(b *testing.B) {
	password := Password("foo")
	log := MustGetLogger("test")

	b.StartTimer()
	for i := 0; i < b.N; i++ {
		log.Debug("log line for %d and this is rectified: %s", i, password)
	}
}
