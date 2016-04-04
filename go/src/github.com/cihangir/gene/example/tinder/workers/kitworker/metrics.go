package kitworker

import (
	"io"
	"net"
	"sync"
	"time"

	"github.com/go-kit/kit/metrics"
	kitdogstatsd "github.com/go-kit/kit/metrics/dogstatsd"
)

var ReportInterval = time.Second * 30

func NewUDPWriter(addr string) (io.Writer, error) {
	udpAddr, err := net.ResolveUDPAddr("udp", addr)
	if err != nil {
		return nil, err
	}
	conn, err := net.DialUDP("udp", nil, udpAddr)
	if err != nil {
		return nil, err
	}

	return conn, nil
}

type metric struct {
	w            io.Writer
	tags         []metrics.Field
	reportTicker <-chan time.Time

	// metrics registry
	counters   map[string]metrics.Counter
	gauges     map[string]metrics.Gauge
	histograms map[string]metrics.Histogram
	mu         sync.Mutex
}

func NewMetric(addr string, tags ...metrics.Field) (*metric, error) {
	w, err := NewUDPWriter(addr)
	if err != nil {
		return nil, err
	}

	return &metric{
		w:            w,
		tags:         tags,
		reportTicker: time.Tick(ReportInterval),

		counters:   make(map[string]metrics.Counter),
		gauges:     make(map[string]metrics.Gauge),
		histograms: make(map[string]metrics.Histogram),
	}, nil
}

func (m *metric) Counter(key string, tags ...metrics.Field) metrics.Counter {
	m.mu.Lock()
	counter, ok := m.counters[key]
	if !ok {
		counter = kitdogstatsd.NewCounterTick(m.w, key, m.reportTicker, append(m.tags, tags...))
		m.counters[key] = counter
	}
	m.mu.Unlock()

	return counter
}

func (m *metric) DeleteCounter(key string) {
	m.mu.Lock()
	delete(m.counters, key)
	m.mu.Unlock()
}

func (m *metric) Gauge(key string, tags ...metrics.Field) metrics.Gauge {
	m.mu.Lock()
	gauge, ok := m.gauges[key]
	if !ok {
		gauge = kitdogstatsd.NewGaugeTick(m.w, key, m.reportTicker, append(m.tags, tags...))
		m.gauges[key] = gauge
	}
	m.mu.Unlock()

	return gauge
}

func (m *metric) DeleteGauge(key string) {
	m.mu.Lock()
	delete(m.gauges, key)
	m.mu.Unlock()
}

func (m *metric) Histogram(key string, tags ...metrics.Field) metrics.Histogram {
	m.mu.Lock()
	histogram, ok := m.histograms[key]
	if !ok {
		histogram = kitdogstatsd.NewHistogramTick(m.w, key, m.reportTicker, append(m.tags, tags...))
		m.histograms[key] = histogram
	}
	m.mu.Unlock()

	return histogram
}

func (m *metric) DeleteHistogram(key string) {
	m.mu.Lock()
	delete(m.histograms, key)
	m.mu.Unlock()
}
